# Specify the provider and access details
provider "aws" {
  region = "${var.region}"
}

#security Groups

resource "aws_security_group" "all" {
    name        = "sg_splunk_all"
    description = "Common rules for all"
    vpc_id      = "${var.vpc_id}"
    # Allow SSH admin access
    ingress {
        from_port   = "22"
        to_port     = "22"
        protocol    = "tcp"
        cidr_blocks = ["${var.admin_cidr_block}"]
    }
    # Allow Web admin access
    ingress {
        from_port   = "${var.httpport}"
        to_port     = "${var.httpport}"
        protocol    = "tcp"
        cidr_blocks = ["${var.admin_cidr_block}"]
    }
    # full outbound  access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group_rule" "interco" {
    # Allow all ports between splunk servers
    type                        = "ingress"
    from_port                   = "0"
    to_port                     = "0"
    protocol                    = "-1"
    security_group_id           = "${aws_security_group.all.id}"
    source_security_group_id    = "${aws_security_group.all.id}"
}


resource "aws_security_group" "searchhead" {
    name             = "sg_splunk_searchhead"
    description      = "Used in the  terraform"
    vpc_id           = "${var.vpc_id}"
    #HTTP  access  from  the  ELB
    ingress {
        from_port        = "${var.httpport}"
        to_port          = "${var.httpport}"
        protocol         = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#template for configuration

data "template_file" "web_conf" {
    template    = "${file("${path.module}/web_conf.tpl")}"
    vars     {
        httpport        = "${var.httpport}"
        mgmtHostPort    = "${var.mgmtHostPort}"
    }
}


data "template_file" "server_conf_master" {
    template    = "${file("${path.module}/server_conf_master.tpl")}"
    vars     {
        replication_factor  = "${var.replication_factor}"
        search_factor       = "${var.search_factor}"
        pass4SymmKey        = "${var.pass4SymmKey}"
    }
}

data "template_file" "server_conf_indexer" {
    template    = "${file("${path.module}/server_conf_indexer.tpl")}"
    vars    {
        mgmtHostPort        = "${var.mgmtHostPort}"
        master_ip           = "${aws_instance.master.private_ip}"
        pass4SymmKey        = "${var.pass4SymmKey}"
        replication_port    = "${var.replication_port}"
    }
}

data "template_file" "server_conf_searchhead" {
    template    = "${file("${path.module}/server_conf_searchhead.tpl")}"
    vars    {
        mgmtHostPort        = "${var.mgmtHostPort}"
        master_ip           = "${aws_instance.master.private_ip}"
        pass4SymmKey        = "${var.pass4SymmKey}"
    }
}


##templating for user data
data "template_file" "user_data_master" {
    template    = "${file("${path.module}/user_data.tpl")}"
    vars    {
        server_conf_content             = "${data.template_file.server_conf_master.rendered}"
        web_conf_content                = "${data.template_file.web_conf.rendered}"
        role                            = "master"
    }
}


data "template_file" "user_data_indexer" {
    template    = "${file("${path.module}/user_data.tpl")}"
    vars    {
        server_conf_content             = "${data.template_file.server_conf_indexer.rendered}"
        web_conf_content                = "${data.template_file.web_conf.rendered}"
        role                            = "indexer"
        indexer_app                     = "${file("indexer_app.sh")}"
        search_app                      = ""   
    }
}

data "template_file" "user_data_searchhead" {
    template    = "${file("${path.module}/user_data.tpl")}"
    vars    {
        server_conf_content             = "${data.template_file.server_conf_searchhead.rendered}"
        web_conf_content                = "${data.template_file.web_conf.rendered}"
        role                            = "searchhead"
        indexer_app                     = ""	
        search_app                      = "${file("search_app.sh")}"
    }
}



#master

resource "aws_instance" "master" {
    connection {
        user = "${var.instance_user}"
    }
    tags {
        Name = "splunk_master"
    }
    ami                         = "${var.ami}"
    instance_type               = "${var.instance_type_indexer}"
    key_name                    = "${var.key_name}"
    subnet_id                   = "${element(split(",", var.subnets), "0")}"
    user_data                   = "${file("master.sh")}"
    vpc_security_group_ids      = ["${aws_security_group.all.id}"]
}


##index cluster autoscaling

resource "aws_launch_configuration" "indexer_base" {
    name = "indexer_base"
    connection {
        user = "${var.instance_user}"
    }
    iam_instance_profile        = "${var.iam_role_indexer}"
    image_id                    = "${var.ami}"
    instance_type               = "${var.instance_type_indexer}"
    key_name                    = "${var.key_name}"
    user_data                   = "${data.template_file.user_data_indexer.rendered}"
    root_block_device {
        volume_size = 80
    }
    security_groups             = ["${aws_security_group.all.id}"]
}


resource "aws_autoscaling_group" "indexer" {
    name = "asg_splunk_indexer"
    availability_zones         = ["${split(",", var.availability_zones)}"]
    vpc_zone_identifier        = ["${split(",", var.subnets)}"]
    min_size                   = "${var.asg_peer_min}"
    max_size                   = "${var.asg_peer_max}"
    desired_capacity           = "${var.asg_peer_desired}"
    launch_configuration       = "${aws_launch_configuration.indexer_base.name}"
    tag {
        key                 = "Name"
        value               = "splunk_indexer"
        propagate_at_launch = true
    }
}

###################### searchhead autoscaling part ######################
resource "aws_launch_configuration" "searchhead_base" {
    name = "lc_splunk_searchhead"
    connection {
        user = "${var.instance_user}"
    }
    iam_instance_profile        = "${var.iam_role_search}"
    image_id                    = "${var.ami}"
    instance_type               = "${var.instance_type_searchhead}"
    key_name                    = "${var.key_name}"
    user_data                   = "${data.template_file.user_data_searchhead.rendered}"
    root_block_device {
        volume_size = 80
    }
    security_groups             = ["${aws_security_group.all.id}", "${aws_security_group.searchhead.id}"]
}

resource "aws_autoscaling_group" "searchhead" {
    name = "asg_splunk_searchhead"
    availability_zones         = ["${var.site1_az}"]
    vpc_zone_identifier        = ["${var.site1_subnet}"]
    min_size                   = "${var.asg_searchhead_min}"
    max_size                   = "${var.asg_searchhead_max}"
    desired_capacity           = "${var.asg_searchhead_desired}"
    launch_configuration       = "${aws_launch_configuration.searchhead_base.name}"
    tag {
        key                 = "Name"
        value               = "splunk_searchhead"
        propagate_at_launch = true
    }
}

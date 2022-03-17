provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}



# creating the network
module "network" {
  source = "./modules/network"

  network_name = "network"
  auto_create_subnetworks = "false"
}

/*
# creating the public subnet
module "public_subnet" {
  source = "./modules/subnetworks"

  subnetwork_name = "public-subnetwork"
  cidr = "10.10.10.0/24"
  subnetwork_region = "asia-northeast3"
  network = module.network.network_name
  depends_on_resoures = [module.network]
  private_ip_google_access = "false"
}*/

# creating the private subnet - server
module "private_subnet" {
  source = "./modules/subnetworks"

  subnetwork_name = "private-subnetwork"
  cidr = "10.10.20.0/24"
  subnetwork_region = "asia-northeast3"
  network = module.network.network_name
  depends_on_resoures = [module.network]
  private_ip_google_access = "false"
}


# creating the private subnet - db
module "private_subnet2" {
  source = "./modules/subnetworks"

  subnetwork_name = "private-subnetwork2"
  cidr = "10.10.30.0/24"
  subnetwork_region = "asia-northeast3"
  network = module.network.network_name
  depends_on_resoures = [module.network]
  private_ip_google_access = "false"
}




# create firewall rule with ssh access to the public instance/s
module "firewall_rule_ssh_all" {
  source = "./modules/firewall"

  firewall_rule_name = "ssh-instances"
  network = module.network.network_name
  protocol_type = "tcp"
  ports_types = null
  source_tags = null
  source_ranges = ["0.0.0.0/0"]
  target_tags = null
}


# firwall rule for private instances
module "firewall_rule_access-db" {
  source = "./modules/firewall"

  firewall_rule_name = "to-db"
  network = module.network.network_name
  protocol_type = "icmp"
  ports_types = null
  source_tags = ["saas-vm","ncu-vm"]
  source_ranges = null
  target_tags = ["db"]
}

# firwall rule for private instances
module "firewall_rule_access-ncu" {
  source = "./modules/firewall"

  firewall_rule_name = "from-ncu"
  network = module.network.network_name
  protocol_type = "icmp"
  ports_types = null
  source_tags = ["ncu-vm"]
  source_ranges = null
  target_tags = ["ncu-analysis-vm"]
}

/*
# create the vm in public subnet
module "public_instance" {
  source = "./modules/instance"

  instance_name = "bastion"
  machine_type = "f1-micro"
  vm_zone = "asia-northeast3-a"
  network_tags = ["bastion", "test"]
  machine_image = "ubuntu-1804-bionic-v20200317"
  subnetwork = module.public_subnet.sub_network_name
  metadata_Name_value = "public_vm"
  
}*/



# create the vm in public subnet
module "private_instance" {
  source = "./modules/instance"

  instance_name = "saas-vm"
  machine_type = "f1-micro"
  vm_zone = "asia-northeast3-b"
  network_tags = ["saas-vm"]
  machine_image = "ubuntu-1804-bionic-v20200317"
  subnetwork = module.private_subnet.sub_network_name
  metadata_Name_value = "private_vm"

}

module "instance-templates" {
  source = "./modules/instance-templates"

  name                 = "saas-instance-template"
  instance_description = "Final Project"
  project              = var.project

  tags = ["allow-saas-instance"]

  network    = module.network.self_link
  subnetwork = module.private_subnet.self_link
 

  
  metadata_startup_script = "scripts/saas-instance.sh"

  labels = {
    environment = terraform.workspace
    purpose     = "Final Project"
  }
}


module "instance-groups" {
  source = "./modules/instance-groups"

  name                      = "saas-instance-group"
  base_instance_name        = "saas"
  region                    = "asia-northeast3"
  distribution_policy_zones = ["asia-northeast3-a", "asia-northeast3-b"]
  instance_template         = module.instance-templates.self_link

  resource_depends_on = [
    //module.router-nat
  ]
}


# create the vm in public subnet - 추가(vm)
module "private_instance2" {
  source = "./modules/instance"

  instance_name = "ncu-vm"
  machine_type = "f1-micro"
  vm_zone = "asia-northeast3-a"
  network_tags = ["ncu-vm"]
  machine_image = "ubuntu-1804-bionic-v20200317"
  //subnetwork = module.private_subnet.sub_network_name

  //network    = module.network.self_link
  subnetwork = module.private_subnet.self_link
  metadata_Name_value = "private_vm"
  
}


module "instance-templates2" {
  source = "./modules/instance-templates"

  name                 = "ncu-instance-template"
  instance_description = "Final Project"
  project              = var.project

  tags = ["allow-ncu-instance"]

  network    = module.network.self_link
  subnetwork = module.private_subnet.self_link
 

  
  metadata_startup_script = "scripts/ncu-instance.sh"

  labels = {
    environment = terraform.workspace
    purpose     = "Final Project"
  }
}


module "instance-groups2" {
  source = "./modules/instance-groups"

  name                      = "ncu-instance-group"
  base_instance_name        = "ncu"
  region                    = "asia-northeast3"
  distribution_policy_zones = ["asia-northeast3-a", "asia-northeast3-b"]
  instance_template         = module.instance-templates2.self_link

  resource_depends_on = [
   // module.router-nat
  ]
}

# create the vm in public subnet - 추가(vm)
module "private_instance3" {
  source = "./modules/instance"

  instance_name = "ncu-analysis-vm"
  machine_type = "f1-micro"
  vm_zone = "asia-northeast3-a"
  network_tags = ["ncu-analysis-vm"]
  machine_image = "windows-cloud/windows-2019"
  //subnetwork = module.private_subnet.sub_network_name
  
  //network    = module.network.self_link
  subnetwork = module.private_subnet.self_link
  metadata_Name_value = "private_vm"
}


# create the vm in public subnet - 추가(vm-db)
module "private_vm_db" {
  source = "./modules/instance"

  instance_name = "db"
  machine_type = "f1-micro"
  vm_zone = "asia-northeast3-c"
  network_tags = ["db"]
  machine_image = "ubuntu-1804-bionic-v20200317"
  subnetwork = module.private_subnet2.sub_network_name
  metadata_Name_value = "private_vm"
}

module "instance-templates3" {
  source = "./modules/instance-templates"

  name                 = "db-instance-template"
  instance_description = "Final Project"
  project              = var.project

  tags = ["allow-db-instance"]

  network    = module.network.self_link
  subnetwork = module.private_subnet.self_link
 

  
  labels = {
    environment = terraform.workspace
    purpose     = "Final Project"
  }
}


module "instance-groups3" {
  source = "./modules/instance-groups"

  name                      = "db-instance-group"
  base_instance_name        = "db"
  region                    = "asia-northeast3"
  distribution_policy_zones = ["asia-northeast3-a", "asia-northeast3-b"]
  instance_template         = module.instance-templates3.self_link

  resource_depends_on = [
    //module.router-nat
  ]
}






module "load-balancer-external" {
  source = "./modules/load-balancer"

  name            = "ncu-lb"
  default_service = module.load-balancer-backend.self_link
}

module "load-balancer-target-http-proxy" {
  source = "./modules/load-balancer-target-http-proxy"

  name    = var.project
  url_map = module.load-balancer-external.self_link
}

module "load-balancer-frontend" {
  source = "./modules/load-balancer-frontend"

  name   = var.project
  target = module.load-balancer-target-http-proxy.self_link
}

module "load-balancer-backend" {
  source = "./modules/load-balancer-backend"

  name = var.project
  backends = [
    module.instance-groups.instance_group,
    module.instance-groups2.instance_group
  ]
  health_checks = [module.load-balancer-health-check.self_link]
}

module "load-balancer-health-check" {
  source = "./modules/health-check"

  name = "hc-asia-northeast3"
}



terraform {
    required_version = "0.11.10"
}

resource "google_compute_instance_group" "rg" {
    name     = "${lower(var.environment)}-${lower(var.subnet_name)}-${lower(var.resource_group_name)}"
    location = "${var.location}"
}

resource "google_compute_instance_template" "as" {
    name                         = "${google_compute_instance_group.rg.name}-ha"
    location                     = "${var.location}"
    resource_group_name          = "${google_compute_instance_group.rg.name}"
    platform_fault_domain_count  = 2
    platform_update_domain_count = 2
    managed                      = true
}

resource "google_compute_network" "ni" {
    count               = "${length(var.vm_name)}"    
    name                = "${lower(var.environment)}${var.location}${lower(var.subnet_name)}-${element(var.vm_name,count.index)}-ni"
    location            = "${var.location}"
    resource_group_name = "${google_compute_instance_group.rg.name}"

    ip_configuration {
        name                          = "${lower(var.environment)}${var.location}${lower(var.subnet_name)}-${element(var.vm_name,count.index)}-ipconfig"
        subnet_id                     = "${var.subnet_path}${upper(var.subnet_name)}"
        private_ip_address_allocation = "Dynamic"
    }
}

resource "google_compute_instance" "vm" {
    count                         = "${length(var.vm_name)}"    
    name                          = "${lower(var.environment)}${var.location}${lower(var.subnet_name)}-${element(var.vm_name,count.index)}"
    location                      = "${var.location}"
    resource_group_name           = "${google_compute_instance_group.rg.name}"

    vm_size                       = "${var.vm_size}"
    network_interface_ids         = ["${element(google_compute_instance_template.ni.*.id, count.index)}"]
    availability_set_id           = "${google_compute_instance_template.as.id}"
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = false

    storage_image_reference {
        publisher = "${var.image_publisher}"
        offer     = "${var.image_offer}"
        sku       = "${var.image_sku}"
        version   = "${var.image_version}"
    }

    storage_os_disk {
        name              = "${lower(var.environment)}${var.location}${lower(var.subnet_name)}-${element(var.vm_name,count.index)}-osdisk"
        managed_disk_type = "${var.os_disk_type}"
        caching           = "ReadWrite"
        create_option     = "FromImage"
    }

    provisioner "file" {
        source      = "${path.module}/auto.sh"
        destination = "/tmp/auto.sh"
        connection {
            type     = "ssh"
            user     = "${var.admin_username}"
            password = "${var.admin_password}"
        }
    }

    provisioner "remote-exec" "install"{
        inline = [
            "chmod a+x /tmp/aut.sh",
            "echo ${var.admin_password} | sudo -S /tmp/post_install.sh > /dev/null"
        ]
        connection {
            type     = "ssh"
            user     = "${var.admin_username}"
            password = "${var.admin_password}"
        }
    }

    os_profile {
        computer_name  = "${lower(var.environment)}${var.location}${lower(var.subnet_name)}-${element(var.vm_name,count.index)}"
        admin_username = "${var.admin_username}"
        admin_password = "${var.admin_password}"
    }
  
    os_profile_linux_config {
        disable_password_authentication = false
    }
}
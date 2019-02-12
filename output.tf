output "resource_group" {
    value = "${azurerm_resource_group.rg.name}"
}

output "availability_set" {
    value = "${azurerm_availability_set.as.name}"
}

output "private_ip_address" {
    value = "${formatlist("%s : %s", azurerm_virtual_machine.vm.*.name, azurerm_network_interface.ni.*.private_ip_address)}"
}

output "vm_name" {
    value = "${azurerm_virtual_machine.vm.*.name}"
}

output "vm_size" {
    value = "${element(azurerm_virtual_machine.vm.*.vm_size,0)}"
}

output "vm_id" {
    value = "${azurerm_virtual_machine.vm.*.id}"
}
#créer un resource group
resource "azurerm_resource_group" "rg" {
 name="${var.name}"
 location="${var.location}"
  tags {
   owner= "${var.owner}"
  }
}

#créer un virtual network

resource "azurerm_virtual_network" "myFirstVnet" {
  name="${var.name_vnet}"
  address_space="${var.adress_space}"
  location="${var.location}"
  resource_group_name= "${azurerm_resource_group.rg.name}"
}

#créer un subnet

resource "azurerm_subnet" "MyFirstSubnet" {
  name                 = "${var.name_subnet}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.myFirstVnet.name}"
  address_prefix       = "${var.address_prefix}"
}

#créer un network security group (ouvrir les ports 22, 80, 443)

resource "azurerm_network_security_group" "myFirstnsg" {
  name                = "${var.nameNsg}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
 
 security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "inbound"
    access                     = "allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
 
 security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

 security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# attibuer une ip publique au resource group

resource "azurerm_public_ip" "myFirstPubIp" {
  name                = "${var.namePubIp}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  allocation_method   = "${var.allocation_method}"
}

# créer network interface controller 

resource "azurerm_network_interface" "myFirstNIC" {
  name                = "nameNIC"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.myFirstnsg.id}"

  ip_configuration {
    name                          = "nameNICConfig"
    subnet_id                     = "${azurerm_subnet.MyFirstSubnet.id}"
    private_ip_address_allocation = "${var.allocation_method}"
    public_ip_address_id          = "${azurerm_public_ip.myFirstPubIp.id}"
  }
}

# créer une machine virtuelle

resource "azurerm_virtual_machine" "myFirstVm" {
  name                  = "${var.nameVm}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.myFirstNIC.id}"]
  vm_size               = "${var.vmSize}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.computerName}"
    admin_username = "${var.admusername}"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.admusername}/.ssh/authorized_keys"
      key_data = "${var.pubKey}"
    }
 }
}




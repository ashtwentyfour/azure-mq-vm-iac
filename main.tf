resource "azurerm_resource_group" "mq_rg" {
  location   = var.region
  name       = var.resource_group
  tags       = {}
}

resource "azurerm_linux_virtual_machine" "mq_vm" {
  admin_password                                         = var.vm_admin_password # Masked sensitive attribute
  admin_username                                         = "mqadmin"
  allow_extension_operations                             = true
  bypass_platform_safety_checks_on_user_schedule_enabled = false
  computer_name                                          = var.vm_name
  disable_password_authentication                        = false
  encryption_at_host_enabled                             = false
  extensions_time_budget                                 = "PT1H30M"
  location                                               = var.region
  max_bid_price                                          = -1
  name                                                   = var.vm_name
  network_interface_ids                                  = ["/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/networkInterfaces/${var.network_interface}"]
  patch_assessment_mode                                  = "ImageDefault"
  patch_mode                                             = "ImageDefault"
  priority                                               = "Regular"
  provision_vm_agent                                     = true
  resource_group_name                                    = var.resource_group
  secure_boot_enabled                                    = false
  size                                                   = "Standard_A1_v2"
  tags                                                   = {}
  vm_agent_platform_updates_enabled                      = false
  vtpm_enabled                                           = false
  provisioner "remote-exec" {
    inline = [
        "sudo docker volume create qm1data",
        "sudo docker run --env LICENSE=accept --env MQ_QMGR_NAME=QM1 --volume qm1data:/mnt/mqm --publish 1414:1414 --publish 9443:9443 --detach --env MQ_APP_USER=app --env MQ_APP_PASSWORD=passw0rd --env MQ_ADMIN_USER=admin --env MQ_ADMIN_PASSWORD=passw0rd --name QM1 ibmcom/mq"
    ]
    connection {
      type = "ssh"
      user = "mqadmin"
      password = var.vm_admin_password
      host = azurerm_public_ip.mq_ip.ip_address
    }
  }
  additional_capabilities {
    hibernation_enabled = false
    ultra_ssd_enabled   = false
  }
  boot_diagnostics {
    storage_account_uri = ""
  }
  os_disk {
    caching                          = "ReadWrite"
    disk_size_gb                     = 30
    name                             = var.disk_name
    storage_account_type             = "StandardSSD_LRS"
    write_accelerator_enabled        = false
  }
  plan {
    name      = "docker-ubuntu-22-04"
    product   = "docker-ubuntu-22-04"
    publisher = "cloud-infrastructure-services"
  }
  source_image_reference {
    offer     = "docker-ubuntu-22-04"
    publisher = "cloud-infrastructure-services"
    sku       = "docker-ubuntu-22-04"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.mq_nic,
  ]
}

resource "azurerm_network_interface" "mq_nic" {
  accelerated_networking_enabled = false
  dns_servers                    = []
  ip_forwarding_enabled          = false
  location                       = var.region
  name                           = var.network_interface
  resource_group_name            = var.resource_group
  tags                           = {}
  ip_configuration {
    name                                               = "ipconfig1"
    primary                                            = true
    private_ip_address                                 = "10.0.0.4"
    private_ip_address_allocation                      = "Dynamic"
    private_ip_address_version                         = "IPv4"
    public_ip_address_id                               = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/publicIPAddresses/${var.public_ip}"
    subnet_id                                          = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/virtualNetworks/${var.virtual_network}/subnets/default"
  }
  depends_on = [
    azurerm_public_ip.mq_ip,
    azurerm_subnet.mq_subnet,
  ]
}

resource "azurerm_network_interface_security_group_association" "mq_nisg_association" {
  network_interface_id      = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/networkInterfaces/${var.network_interface}"
  network_security_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/networkSecurityGroups/${var.network_security_group}"
  depends_on = [
    azurerm_network_interface.mq_nic,
    azurerm_network_security_group.mq_nsg,
  ]
}

resource "azurerm_network_security_group" "mq_nsg" {
  location            = var.region
  name                = var.network_security_group
  resource_group_name = var.resource_group
  tags = {}
  depends_on = [
    azurerm_resource_group.mq_rg,
  ]
}

resource "azurerm_network_security_rule" "mq_nsr_1" {
  access                                     = "Allow"
  description                                = ""
  destination_address_prefix                 = "*"
  destination_address_prefixes               = null
  destination_application_security_group_ids = []
  destination_port_range                     = "80"
  destination_port_ranges                    = null
  direction                                  = "Inbound"
  name                                       = "HTTP"
  network_security_group_name                = var.network_security_group
  priority                                   = 320
  protocol                                   = "Tcp"
  resource_group_name                        = var.resource_group
  source_address_prefix                      = "*"
  source_address_prefixes                    = null
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = null
  depends_on = [
    azurerm_network_security_group.mq_nsg,
  ]
}

resource "azurerm_network_security_rule" "mq_nsr_2" {
  access                                     = "Allow"
  description                                = ""
  destination_address_prefix                 = "*"
  destination_address_prefixes               = null
  destination_application_security_group_ids = []
  destination_port_range                     = "1414"
  destination_port_ranges                    = null
  direction                                  = "Inbound"
  name                                       = "MQPort"
  network_security_group_name                = var.network_security_group
  priority                                   = 330
  protocol                                   = "Tcp"
  resource_group_name                        = var.resource_group
  source_address_prefix                      = "*"
  source_address_prefixes                    = null
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = null
  depends_on = [
    azurerm_network_security_group.mq_nsg,
  ]
}

resource "azurerm_network_security_rule" "mq_nsr_3" {
  access                                     = "Allow"
  description                                = ""
  destination_address_prefix                 = "*"
  destination_address_prefixes               = null
  destination_application_security_group_ids = []
  destination_port_range                     = "9443"
  destination_port_ranges                    = null
  direction                                  = "Inbound"
  name                                       = "MQConsolePort"
  network_security_group_name                = var.network_security_group
  priority                                   = 340
  protocol                                   = "*"
  resource_group_name                        = var.resource_group
  source_address_prefix                      = "*"
  source_address_prefixes                    = null
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = null
  depends_on = [
    azurerm_network_security_group.mq_nsg,
  ]
}

resource "azurerm_network_security_rule" "mq_nsr_4" {
  access                                     = "Allow"
  description                                = ""
  destination_address_prefix                 = "*"
  destination_address_prefixes               = null
  destination_application_security_group_ids = []
  destination_port_range                     = "22"
  destination_port_ranges                    = null
  direction                                  = "Inbound"
  name                                       = "SSH"
  network_security_group_name                = var.network_security_group
  priority                                   = 300
  protocol                                   = "Tcp"
  resource_group_name                        = var.resource_group
  source_address_prefix                      = "*"
  source_address_prefixes                    = null
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = null
  depends_on = [
    azurerm_network_security_group.mq_nsg,
  ]
}

resource "azurerm_public_ip" "mq_ip" {
  allocation_method       = "Static"
  ddos_protection_mode    = "VirtualNetworkInherited"
  idle_timeout_in_minutes = 4
  ip_tags                 = {}
  ip_version              = "IPv4"
  location                = var.region
  name                    = var.public_ip
  resource_group_name     = var.resource_group
  sku                     = "Standard"
  sku_tier                = "Regional"
  tags                    = {}
  zones                   = []
  depends_on = [
    azurerm_resource_group.mq_rg,
  ]
}

resource "azurerm_virtual_network" "mq_vnet" {
  address_space                  = ["10.0.0.0/16"]
  dns_servers                    = []
  location                       = var.region
  name                           = var.virtual_network
  private_endpoint_vnet_policies = "Disabled"
  resource_group_name            = var.resource_group
  tags = {}
  depends_on = [
    azurerm_resource_group.mq_rg,
  ]
}

resource "azurerm_subnet" "mq_subnet" {
  address_prefixes                              = ["10.0.0.0/24"]
  default_outbound_access_enabled               = true
  name                                          = "default"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = var.resource_group
  service_endpoint_policy_ids                   = []
  service_endpoints                             = []
  virtual_network_name                          = var.virtual_network
  depends_on = [
    azurerm_virtual_network.mq_vnet,
  ]
}

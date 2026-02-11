resource "tls_private_key" "global_ssh_key" {
   algorithm = "RSA"
   rsa_bits  = 4096


   provisioner "local-exec" {
      command = "./create_pem.sh ${var.test_mode}" 

      environment = {
         SECKEY = tls_private_key.global_ssh_key.private_key_pem 
      }
   }
}

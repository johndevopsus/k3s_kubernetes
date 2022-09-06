resource "random_password" "k3s_cluster_secret" {
  length  = 30
  special = false
}
# random_password ile 30 karakterlik bir secret key uretiyoruz ve bunu token olarak main.tf dosyasi icerisinde Worker'da User_Data kisminde variable olarak aldirip K3S kurulumunda TOKEN olarak kullaniyoruz.
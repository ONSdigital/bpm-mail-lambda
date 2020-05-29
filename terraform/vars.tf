variable "app" {
    type = string
    default = "bpm-mail"
}

#deployment stage
variable "stage" {
    type = string
    default = "dev"
}

variable "domain" {
    type = string
    default = "bpm.ons.digital"
}

variable "BPM_USER" {
    type = string
}

variable "BPM_PW" {
    type = string
}
(defcustom lightsail-server-list nil "list of lightsail servers")

(setq aws-ec2-machine-types (list "t2.nano" "t2.micro" "t2.small" "t2.medium" "t2.large" "t2.xlarge" "t2.2xlarge" "m4.large" "m4.xlarge" "m4.2xlarge" "m4.4xlarge" "m4.10xlarge" "m4.16xlarge" "m3.medium" "m3.large" "m3.xlarge" "m3.2xlarge" "t2.nano" "t2.micro" "t2.small" "t2.medium" "t2.large" "t2.xlarge" "t2.2xlarge" "m4.large" "m4.xlarge" "m4.2xlarge" "m4.4xlarge" "m4.10xlarge" "m4.16xlarge" "m3.medium" "m3.large" "m3.xlarge" "m3.2xlarge"))

(async-start
 (lambda ()
   (split-string
    (shell-command-to-string "aws ec2 describe-regions  | jq ' .[]'  | jq '.[] | .RegionName'") "\n"))
 (lambda (result)
   (progn (setq aws-regions result)
          (message "region list configured"))))

(defun aws (command &optional output-format)
  (interactive "scommmand")
  (if (not (string= "" output-format))
      (async-shell-command (concat "aws " command " --output " output-format)
                           (concat "*AWS* - running command - " command))
    (async-shell-command (concat "aws " command)
                         (concat "*AWS* - running command - " command))))

(defun aws:version ()
  (interactive)
  (aws "--version"))

(defun ec2:list-instances ()
  (interactive)
  (async-shell-command "aws ec2 describe-instances"
                       (concat "*EC2 - list instances*")
                       ))

(defun ec2:list-instances-table ()
(interactive)
(async-shell-command "aws ec2 describe-instances --output table"
		     (concat "*EC2 - list instances table*")))

(defun ec2:get-images-by-region (region)
  (interactive "swhat region: ")
  (async-shell-command (concat "aws ec2 describe-images --owners self --region " region)))

(defun ec2:search-for-ami (query)
  (interactive "squery: ") 
  (async-shell-command (concat "aws ec2 describe-images --owners amazon --filters Name=architecture,Values=x86_64 | grep " query)))

(defun lightsail:get-instances ()
  (interactive)
  (let ((region (completing-read "region: " aws-regions)))
    (aws (concat "lightsail " "get-instances"))))



(defun lightsail:run-command-int (command) 
  (interactive "sCommand: ")
  (let ((server (completing-read "server:"  lightsail-server-list)))
      (async-shell-command (concat "clush -o" 
                                   "\""
                                   " -i ~/.ssh/" server
                                   " -F ~/.ssh/config_" server
                                   "\""
                                   " -w "
                                   "'" server "'"
                                   " -B "
                                   "\""
                                   command
                                   "\""

                                   )
                           (concat "*lightsail* - " server " " command ))))

(defun lightsail:run-command (command server) 
  (interactive "sCommand: \nsServer: ")
   (async-shell-command (concat "clush -o" 
                                   "\""
                                   " -i ~/.ssh/" server
                                   " -F ~/.ssh/config_" server
                                   "\""
                                   " -w "
                                   "'" server "'"
                                   " -B "
                                   "\""
                                   command
                                   "\"")
                           (concat "*lightsail* - " server "" command )))

(defun lightsail:init-dev-environment ()
  (interactive)
  (let ((server (completing-read "server:"  lightsail-server-list)))
    (lightsail:run-command (concat
                            "sudo timedatectl set-timezone America/Los_Angeles"
                            "sudo apt-get -y update;"
                            "sudo apt-get -y install docker;"
                            "sudo apt-get -y install python-minimal;"
                            "sudo apt-get -y install supervisor;"
                            "sudo apt-get -y install collectdg")
                           server)))

(defun lightsail:change-timezone-to-pacific ()
    (let ((server (completing-read "server:"  lightsail-server-list)))
      (lightsail:run-command (concat
                              "sudo timedatectl set-timezone America/Los_Angeles")
                             server)))

(defun eb:install-cli ()
(interactive)
(pip:install-in-current-virtualenv "awsebcli"))

(defun eb:check-dns-availability (domain)
  (interactive "sdomain ")
  (async-shell-command (concat "aws elasticbeanstalk check-dns-availability --cname-prefix " domain)))

(defun s3:create-bucket (name)
  (interactive "sname: ")
  (let ((region (completing-read "region" aws-s3-regions)))
    (async-shell-command (concat "aws s3api create-bucket --bucket " name " --region " region " --create-bucket-configuration " region))))

(defun route53:get-hosted-zones ()
(interactive)
(async-shell-command "aws route53 list-hosted-zones"))

(defun route53:get-hosted-zones-by-name ()
  (interactive)
  (async-shell-command "aws route53 list-hosted-zones | jq '.HostedZones[].Name'"))

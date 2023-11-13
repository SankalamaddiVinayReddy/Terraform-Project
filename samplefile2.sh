#!/bin/bash
apt update
apt install -y apache2


# Create a simple HTML file with the portfolio content and display the images
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>
  <h1>Sever2</h1>
  </title>
</head>
<body>
  <h1>Terraform Project Server 2</h1>
  
  <p>Welcome to  Vinay Reddy Terraform project</p>
  
</body>
</html>
EOF

# Start Apache and enable it on boot
systemctl start apache2
systemctl enable apache2
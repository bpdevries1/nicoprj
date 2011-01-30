<body>
<script language="php">
print "In het begin";

$username="nico";
$password="nico42";
$database="database";

$first=$_POST['first'];
$last=$_POST['last'];
$phone=$_POST['phone'];
$mobile=$_POST['mobile'];
$fax=$_POST['fax'];
$email=$_POST['email'];
$web=$_POST['web'];

mysql_connect("localhost",$username,$password) or die("Could not connect to mysql");
@mysql_select_db($database) or die( "Unable to select database");

$query = "INSERT INTO contacts VALUES ('','$first','$last','$phone','$mobile','$fax','$email','$web')";
mysql_query($query) or die("Cannot execute insert statement");

mysql_close();

print "Aan het einde";

</script>
</body>


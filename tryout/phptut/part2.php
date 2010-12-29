<script language="php">
print("Hello World!");


$welcome_text = "Hello and welcome to my website.";
print $welcome_text;

print "<font face=\"Arial\" color=\"#FF0000\">Hello and welcome to my website.</font>";

$number = 10;
$current = 0;
while ($current < $number) {
++$current;
print "$current<br>";
}

$names[0] = 'John';
$names[1] = 'Paul';
$names[2] = 'Steven';
$names[3] = 'George';
$names[4] = 'David';

echo "The third name is $names[2]";

$names[b] = "Nico";

echo "<br/>";

echo $names["a"];

echo "<br/>The name2 is $names[b]";

$number = 5;
$x = 0;
while ($x < $number) {
  $namenumber = $x + 1;
  echo "Name $namenumber is $names[$x]<br>";
  ++$x;
}

$to = "test@nicodevreeze.nl";
$subject = "PHP Is Great";
$body = "PHP is one of the best scripting languages around";
$headers = "From: webmaster@gowansnet.com\n";

if(mail($to,$subject,$body,$headers)) {
  echo "An e-mail was sent to $to with the subject: $subject";
} else {
  echo "There was a problem sending the mail. Check your code and make sure that the e-mail address $to is valid";
}

</script>

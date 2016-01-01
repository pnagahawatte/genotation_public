<?php

$upload_dir = 'pdfuploads';

#if (!empty($_POST["file"])) {
#if (!empty($_POST["file"])) {

#$utf8=$_POST['file'];
#$utf8=$_POST['file'];
#error_log(strlen($utf8));
#$handle = fopen("test.pdf", "w");
#fwrite($handle, $utf8);
#fclose($handle);
#file_put_contents('restored.pdf', $utf8);
#}

$utf8 = file_get_contents($_POST['file']);
?>
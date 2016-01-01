<?php

$uploadDir = '/var/www/Genotation/temp/';
//$uploadDir = '';
$tempFile = $_FILES['file']['tmp_name'];


if (!empty($_FILES)) {

	$tempFile = $_FILES['file']['tmp_name'];
	$mainFile = $uploadDir . basename($_FILES['file']['name']);
	$fileName = strtolower($_FILES['file']['name']);
	// Check file extension
	if((end(explode('.', $fileName))) == 'pdf') 
	{
		// Check the MIME type
		$fileinfo = getimagesize($_FILES['file']['tmp_name']);
		move_uploaded_file($tempFile,$mainFile); 
	}
	else { print "Genotation only accepts pdf files. Please use the browser back button to upload a pdf file"; }
}
?>

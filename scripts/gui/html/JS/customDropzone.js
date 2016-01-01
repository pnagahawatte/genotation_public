//<script type="text/javascript">
   Dropzone.options.dropzone = {
		maxFiles: 1,
		autoProcessQueue: false,
		uploadMultiplle: false,
		parallelUploads: 100,
		init: function() {
		var submitButton = document.querySelector("#submit-file")
			myDropzone = this; // closure

			submitButton.addEventListener("click", function() {
				//myDropzone.processQueue(); // Tell Dropzone to process all queued files.
				//e.preventDefault();
				//e.stopPropagation();
				myDropzone.processQueue();
			});
			this.on("addedfile", function() {
		  // Show submit button here and/or inform user to click it.
				document.getElementById("submit-file").style.display = "block";
			});
			this.on("sending", function() {
			  // Gets triggered when the form is actually being sent.
			  // Hide the success button or the complete form.
			});
			this.on("success", function(file, response) {
			  // Gets triggered when the files have successfully been sent.
			  // Redirect user or notify of success.
			  var path = "DisplayAnnotation.pl?fileurl=";
			  var url = path.concat(file.name);
			  window.location = url;
			});
			this.on("error", function(file, response) {
			  // Gets triggered when there was an error sending the files.
			  // Maybe show form again, and notify user of error
			});
		},
        accept: function(file, done) {
            console.log(file);
            if (file.type != "application/pdf") {
                done("Error! Files of this type are not accepted");
            }
            else { done(); }
        }
    };
 //</script>
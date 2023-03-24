Dialog.create("SIFT Registration");
choicearray=newArray("yes","no");
Dialog.addChoice("Are your first slices mostly empty data?", choicearray, choicearray[1]) 
Dialog.addNumber("SIFT Initial Blur (Larger blur gives less features)", 1.5)
Dialog.addNumber("SIFT Steps between min and max image size", 3)
Dialog.addNumber("SIFT Minsize of image used for registration steps", 64)
Dialog.addNumber("SIFT Maxsize of image used for registration steps",512)
Dialog.addNumber("SIFT Descriptor Size",8)
Dialog.addNumber("Max alignment error (px)",25)

Dialog.show();

reversestack=Dialog.getChoice();
initialblur=Dialog.getNumber();
steps=Dialog.getNumber();
minsize=Dialog.getNumber();
maxsize=Dialog.getNumber();
descriptorsize=Dialog.getNumber();
maxerror=Dialog.getNumber();

print("\\Clear");
run("Conversions...", "scale");


title=getTitle();
//print(title);
getDimensions(width, height, channels, slices, frames);
getVoxelSize(width, height, depth, unit);
metadata=getMetadata("Info");
bitnumber=bitDepth();


setBatchMode("hide");

if (channels > 1) {
	run("Split Channels");
}

//Reverse each channel so the last slice become first
//this is useful if the stacks to register do not have any image
//feature in the first slices (i.e. they are empty)

if (reversestack=="yes") {
	if (channels > 1) {
		for (i = 1; i <= channels; i++) {
			selectWindow("C"+i+"-"+title);
			print("C"+i+"-"+title);
			run("Reverse");
		}
	} else {
		run("Reverse");
	}
}

//Create a registration channel by summing all the channels and 
//stretching the contrast on a per slice basis.
//This increases the likelyhood that SIFT will find a image features throughout the stack

if (channels == 1) {
run("Duplicate...", "title=[Result of C1-"+title+"] duplicate");
}
if (channels >= 2) {
imageCalculator("Add create 32-bit stack", "C1-"+title,"C2-"+title);
}
if (channels >= 3) {
imageCalculator("Add stack", "Result of C1-"+title,"C3-"+title);
}
if (channels == 4) {
imageCalculator("Add stack", "Result of C1-"+title,"C4-"+title);
}


selectWindow("Result of C1-"+title);
rename("C"+channels+1+"-"+title);

run("Enhance Contrast...", "saturated=1 normalize process_all");
run(bitnumber+"-bit");


//merge the registration channel to the others before attempting SIFT registration

if (channels == 1) {
run("Merge Channels...", "c1="+title+" c2=C2-"+title+" create");
rename(title);
}
if (channels == 2) {
run("Merge Channels...", "c1=C1-"+title+" c2=C2-"+title+" c3=C3-"+title+" create");
}
if (channels == 3) {
run("Merge Channels...", "c1=C1-"+title+" c2=C2-"+title+" c3=C3-"+title+" c4=C4-"+title+" create");
}
if (channels == 4) {
run("Merge Channels...", "c1=C1-"+title+" c2=C2-"+title+" c3=C3-"+title+" c4=C4-"+title+" c5=C5-"+title+" create");
}

run("Linear Stack Alignment with SIFT MultiChannel", 
	"registration_channel="+channels+1+" initial_gaussian_blur="+initialblur+" steps_per_scale_octave="+steps+" minimum_image_size="+minsize+" maximum_image_size="+maxsize+" feature_descriptor_size="+descriptorsize+" feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 maximal_alignment_error="+maxerror+" inlier_ratio=0.05 expected_transformation=Translation interpolate");
rename("temp-registered");
//remove the registration channel from the stack after SIFT
run("Duplicate...", "duplicate channels=1-"+channels);
rename("Aligned_"+title);
selectWindow("temp-registered");
close();


selectWindow(title);
rename("temp");
run("Duplicate...", "duplicate channels=1-"+channels);
rename(title);
selectWindow("temp");
close();


selectWindow(title);
if (reversestack=="yes") {
	if (channels > 1) {
		run("Split Channels");
		
		
		for (i = 1; i <= channels; i++) {
			selectWindow("C"+i+"-"+title);
			run("Reverse");
		}
		
		if (channels == 2) {
		run("Merge Channels...", "c1=C1-"+title+" c2=C2-"+title+" create");
		}
		if (channels == 3) {
		run("Merge Channels...", "c1=C1-"+title+" c2=C2-"+title+" c3=C3-"+title+" create");
		}
		if (channels == 4) {
		run("Merge Channels...", "c1=C1-"+title+" c2=C2-"+title+" c3=C3-"+title+" c4=C4-"+title+" create");
		}
	} else {
		run("Reverse");
	}
}




selectWindow("Aligned_"+title);

if (reversestack=="yes") {
	if (channels > 1) {
		run("Split Channels");
		
		
		for (i = 1; i <= channels; i++) {
			selectWindow("C"+i+"-Aligned_"+title);
			print("C"+i+"-"+title);
			run("Reverse");
		}
		
		if (channels == 2) {
		run("Merge Channels...", "c1=C1-Aligned_"+title+" c2=C2-Aligned_"+title+" create");
		}
		if (channels == 3) {
		run("Merge Channels...", "c1=C1-Aligned_"+title+" c2=C2-Aligned_"+title+" c3=C3-Aligned_"+title+" create");
		}
		if (channels == 4) {
		run("Merge Channels...", "c1=C1-Aligned_"+title+" c2=C2-Aligned_"+title+" c3=C3-Aligned_"+title+" c4=C4-Aligned_"+title+" create");
		}
	} else {
		run("Reverse");
	}
}

setBatchMode("exit and display");

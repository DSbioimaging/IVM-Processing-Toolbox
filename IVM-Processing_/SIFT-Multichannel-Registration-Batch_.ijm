/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") rawdatafolder
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".oir") suffix


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







rootfolder=rawdatafolder+File.separator;


setBatchMode("hide");


close("*");
print("\\Clear");

processFolder(rawdatafolder);

setBatchMode("exit and display");
showMessage("Batch Processing Complete!");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			folderpath=input + File.separator + list[i];
			folderpath=replace(folderpath, "/", "");
			startpoint=lengthOf(rawdatafolder);
			
			if (lengthOf(folderpath)>startpoint) {
				folderpath=substring(folderpath, startpoint);
				File.makeDirectory(output+folderpath);
				print("Creating new directory in "+output+folderpath);
				folderpathstring=folderpath;
			}	
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {

	savepath=input + File.separator + file;
	savepath=replace(savepath, "/", "");
	savepath=substring(savepath, lengthOf(rootfolder), lengthOf(savepath)-3);
	savepath=output+File.separator+savepath+"tif";
	

	if (!File.exists(savepath)) {
	
	run("Conversions...", "scale");
	
	inputfile=input + File.separator + file;
	inputfile=replace(inputfile, "/", "");
	print("Processing: " + inputfile);
	run("Bio-Formats Importer", "open=["+inputfile+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

	title=getTitle();
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(width, height, depth, unit);
	metadata=getMetadata("Info");
	bitnumber=bitDepth();
	
	if (slices > 1 || frames > 1) {
	
	
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


		print("Saving to: " + savepath);
		save(savepath);

	}	
	}
close("*");
}

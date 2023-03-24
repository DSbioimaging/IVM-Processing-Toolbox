/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") rawdatafolder
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".oir") suffix

rootfolder=rawdatafolder+File.separator;
fijifolder=getDirectory("imagej");
IJtemp=fijifolder+"IVMDenoising"+File.separator+"ImageJ"+File.separator;
File.delete(IJtemp+"temp.tif");
File.delete(IJtemp+"temp_denoised.tif");

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

//print("folderpath is "+folderpath);

	savepath=input + File.separator + file;
	savepath=replace(savepath, "/", "");
	savepath=substring(savepath, lengthOf(rootfolder), lengthOf(savepath)-3);
	savepath=output+File.separator+savepath+"tif";
	

	if (!File.exists(savepath)) {
	print("Denoised file will be saved in "+savepath);	
	// Do the processing here by adding your own code.
	// Leave the print statements until things work, then remove them.
	//print("Processing: " + input + File.separator + file);
	
	inputfile=input + File.separator + file;
	inputfile=replace(inputfile, "/", "");
	print("Processing: " + inputfile);
	

	run("Bio-Formats Importer", "open=["+inputfile+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	metadata=getMetadata("Info");
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(width, height, depth, unit);
	stackname = getTitle();




	selectWindow(stackname);

	save(IJtemp+"temp.tif");
	close();

	exec(IJtemp+"ImageJ.exe -macro \""+IJtemp+"PureDenoiseIJ.ijm\"");

	waiting=0;
	do {
      wait(1500);
      //print("Denoising Image in Matlab...");
      if (File.exists(IJtemp+"temp-denoised.tif")) {
      waiting=1;
      }
   } while (waiting<1);
   
   
	print("\\Clear");
	run("Bio-Formats Importer", "open=["+IJtemp+"temp-denoised.tif] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	File.delete(IJtemp+"temp.tif");
	File.delete(IJtemp+"temp_denoised.tif");


	
	

	
		setMetadata("Info", metadata);
		setVoxelSize(width, height, depth, unit);
		run("Properties...", "slices="+slices+" frames="+frames);

		print("Saving to: " + savepath);
		save(savepath);

		
}
close("*");
}

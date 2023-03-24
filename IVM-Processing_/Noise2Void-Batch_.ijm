/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") rawdatafolder
#@ File (label = "Output directory", style = "directory") output
#@ File (label = "N2V network(s) directory", style = "directory") n2vfolder
#@ String (label = "File suffix", value = ".tif") suffix
#@ String(label="Are the N2V network(s) 3D?", choices={"yes","no"}, style="radioButtonHorizontal") N2V3D
#@ int n2vnumber (label="Number of channels in raw data", value=1, min=1, max=4, style="slider") 

if (n2vnumber==0) {
	n2vnumber=1;
}


networks = getFileList(n2vfolder);

networkslist=newArray;
	for (i = 0; i < networks.length; i++) {
		if (endsWith(networks[i], ".zip")) {
			networkslist=Array.concat(networkslist,networks[i]);

		}
	}
	
Dialog.create("N2Vnetworks");
Dialog.addMessage("Select the correct N2Vnetwork for each channel");
Dialog.addChoice("Ch1-N2V", networkslist);
if (n2vnumber>=2) {
	Dialog.addChoice("Ch2-N2V", networkslist);
}
if (n2vnumber>=3) {
	Dialog.addChoice("Ch3-N2V", networkslist);
}
if (n2vnumber>=4) {
	Dialog.addChoice("Ch4-N2V", networkslist);
}
Dialog.show();

n2vCh1=Dialog.getChoice();
if (n2vnumber>=2) {
	n2vCh2=Dialog.getChoice();
}
if (n2vnumber>=3) {
	n2vCh3=Dialog.getChoice();
}
if (n2vnumber>=4) {
	n2vCh4=Dialog.getChoice();
}


networks=newArray(n2vfolder+File.separator+n2vCh1);

if (n2vnumber>=2) {
	networks=Array.concat(networks,n2vfolder+File.separator+n2vCh2);
}
if (n2vnumber>=3) {
	networks=Array.concat(networks,n2vfolder+File.separator+n2vCh3);
}
if (n2vnumber>=4) {
	networks=Array.concat(networks,n2vfolder+File.separator+n2vCh4);
}


setBatchMode("hide");
close("*");

rootfolder=rawdatafolder+File.separator;
fijifolder=getDirectory("imagej");
N2Vtemp=fijifolder+File.separator;
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
	print("Denoised file will be saved in "+savepath);	
	inputfile=input + File.separator + file;
	inputfile=replace(inputfile, "/", "");
	print("Processing: " + inputfile);
	run("Bio-Formats Importer", "open=["+inputfile+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

	metadata=getMetadata("Info");
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(width, height, depth, unit);
	print("savepath "+savepath);
	stackname=getTitle();
	
if (n2vnumber==channels) {
	

	for (j = 1; j <= channels; j++) {
	selectWindow(stackname);
    run("Duplicate...", "title=C" + j + " duplicate channels=" + j);
	
	File.delete(N2Vtemp+"temp.tif");

	save(N2Vtemp+"temp.tif");
	
	print("network is "+ n2vfolder+File.separator+networks[j-1]);
	print("input for denoising is "+output+File.separator+"temp.tif");
	
	if (N2V3D=="yes") {
		run("N2V predict", "modelfile="+networks[j-1]+" input="+N2Vtemp+"temp.tif axes=XYZb batchsize=1 numtiles=12 showprogressdialog=false convertoutputtoinputformat=true");
	} else {
		run("N2V predict", "modelfile="+networks[j-1]+" input="+N2Vtemp+"temp.tif axes=XYb batchsize=1 numtiles=1 showprogressdialog=false convertoutputtoinputformat=true");
	}

	wait(3000);
	File.delete(output+File.separator+"temp.tif");
	selectWindow("output");
	rename("C"+j+"-temp");
	setMetadata("Info", metadata);
	setVoxelSize(width, height, depth, unit);
	run("Properties...", "channels=1 slices="+slices+" frames="+frames);
	File.delete(N2Vtemp+"temp.tif");
		
	}

	
		if (channels==4) {
	run("Merge Channels...", "c1=C1-temp c2=C2-temp c3=C3-temp c4=C4-temp create");
			Stack.setSlice(round(slices/2));
			Stack.setFrame(round(frames/2));


		Stack.setChannel(1);
		run("Grays");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Red");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(3);
		run("Green");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(4);
		run("Blue");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
	}
	
			if (channels==3) {
	run("Merge Channels...", "c1=C1-temp c2=C2-temp c3=C3-temp create");
					Stack.setSlice(round(slices/2));
			Stack.setFrame(round(frames/2));
		Stack.setChannel(1);
		run("Red");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Green");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(3);
		run("Blue");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
	}
	
				if (channels==2) {
	run("Merge Channels...", "c1=C1-temp c2=C2-temp create");
					Stack.setSlice(round(slices/2));
			Stack.setFrame(round(frames/2));
			
		Stack.setChannel(1);
		run("Red");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
		Stack.setChannel(2);
		run("Green");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");
		
	}
	
					if (channels==1) {
					Stack.setSlice(round(slices/2));
			Stack.setFrame(round(frames/2));
		Stack.setChannel(1);
		run("Grays");
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.35");

		
	}
	
	
	print("Saving to: " + savepath);
	save(savepath);
	}
	close("*");

}
}
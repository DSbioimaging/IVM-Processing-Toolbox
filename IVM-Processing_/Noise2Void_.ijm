
#@ File (label = "N2V network(s) directory", style = "directory") n2vfolder
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


fijifolder=getDirectory("imagej");
N2Vtemp=fijifolder+File.separator;
setBatchMode("hide");

	metadata=getMetadata("Info");
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(width, height, depth, unit);
	stackname=getTitle();

if (n2vnumber==channels) {


	for (j = 1; j <= channels; j++) {
	selectWindow(stackname);
    run("Duplicate...", "title=C" + j + " duplicate channels=" + j);
	File.delete(N2Vtemp+"temp.tif");
	save(N2Vtemp+"temp.tif");
	close();
	
	if (N2V3D=="yes") {
		run("N2V predict", "modelfile="+networks[j-1]+" input="+N2Vtemp+"temp.tif axes=XYZb batchsize=1 numtiles=12 showprogressdialog=false convertoutputtoinputformat=true");
	} else {
		run("N2V predict", "modelfile="+networks[j-1]+" input="+N2Vtemp+"temp.tif axes=XYb batchsize=1 numtiles=1 showprogressdialog=false convertoutputtoinputformat=true");
	}

	wait(3000);
	File.delete(N2Vtemp+"temp.tif");
	selectWindow("output");
	rename("C"+j+"-temp");
	setMetadata("Info", metadata);
	setVoxelSize(width, height, depth, unit);
	run("Properties...", "channels=1 slices="+slices+" frames="+frames);
	
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
	

}

setBatchMode("exit and display");
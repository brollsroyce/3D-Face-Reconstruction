# 3D-Face-Reconstruction
The presented codes allow you to reconstruct a 3D face using three 2D images.
Please calibrate your camera and save your camera parameters as `cameraParams` before proceding.
Run `main.m` with the correct images loaded in it.
If you want to use your own images, replace/add them in the 'Test' folder.

##How this works
After the images are read, they are segmented with the help of k-means segmentation, in order to remove background information.
Using this, we can create a mask which we can then use on the original image, to get an accurate image that shows only the face.
Once this is done for a set of 3 images (Left,middle and right) a disparity map is generated, to get depth information.
A point cloud is generated for each image pair (L-M and M-R) which is then merged and smoothened.
Finally, a 3D mesh is generated with this information.

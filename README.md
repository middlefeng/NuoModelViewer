# Nuo Model Viewer

A simple Wavefront OBJ viewer.

## Latest Update

* Ground shadow

<p align="left">
  <img height="300" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-4J-Ground.jpg"/>
  <img height="300" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F4J-ground-front.jpg"/>
</p>

* Skybox.

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F4JOLOBJHD.png"/>
</p>

* BRDF mode. Fix artifacts in specular lighting.
* Save to high resolution PNG (up to 3900 px).
* Rotate individual parts (mandatory for the varying-geometry wing plane model!).

<p align="left">
  <img width="800" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-14-wing.png"/>
</p>

* Adjustable shadowing PCF and bias to alliviate artifacts.
* Preliminary shadowing for two of the four light sources.

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/FA-18-shadow.png"/>
</p>

* Load/save scene parameters (postion, light source direction, etc.).
* Normal texture.
* Light source configuration.
* Multiple light sources.

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-16.jpg"/>
</p>

* Adjustable lighting direction.
* Better handling to material opacity.

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/2016-0913-LP.jpg"/>
</p>

## Screenshots on Development

<p align="left">
  <img width="600" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/2016-0908-ModelViewer.jpg"/>
</p>


## TODO

* Order-independent transparency.
* <del>Bump texture.</del>
* <del>Direction of lgiht source.</del>
* <del>Intensity of light source.</del>
* <del>Mutilple light sources.</del>
* <del>Selectable list of object.</del>
* <del>Surface smooth.</del>
* <del>Shadow to model</del>
* Shadow to ground.
* <del>Per light-source, per-surface shadow properties (bias, soft edge).</del>
* <del>Cull mode.</del>
* Surrounding.
  * <del>Cubmap skybox.</del>
  * Water (for ship model).
* Motion blur (especially for rotating parts like rotor).
* Detailed properties panel for indiviudal model parts.
  * <del>Smooth options (everywhere, texture discontinuiation only, etc).</del>
  * <del>Material opacity adjustment.
  * Material adjustment (specular, colors, etc).
* Reflection.
* <del>BRDF mode.</del>
* Model visualization
  * Triangle mesh
  * Normal/tangent visualization
  

## Early Screenshots

Screenshot of the first version (left). Add support to simple transparency (right).
<p align="left">
  <img height="200" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/ver0.0.jpg"/>
  <img height="200" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/ver0.0-transparency.jpg"/>
</p>


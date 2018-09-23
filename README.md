# Nuo Model Viewer

A simple Wavefront OBJ viewer.

## Latest Update

* Ray tracing based shadow.
  * Direct lighting shadow.
  * Indirect lighting (ambient) with physically-based occlusion.
  * Physically based effect for the shadow overlay (blend-in with photographic scene).

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-35-ray_tracing.png"/>
</p>

* Overlay indicator for selected parts.

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-35-selection.png"/>
</p>

* Transformation on the entire scene accurately around the scene's center.
* More accurate bounds calculation (improving shadow map sampling quality).
* User selection on GPU.
* Better take advantage of dedicated video memory by using private buffers. Especially important for <a href="https://www.instagram.com/p/BflXSN7BsUY/">desktop-class graphics card or external GPU</a>).
* Background loading.
* Motion blur.
* Blending with real-scene background.

<p align="left">
  <img width="450" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/UH60.png"/>
</p>

* Ambient occlusion.

<p align="left">
  <img height="295" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/SDROBJ-no-occlusion.jpg"/>
</p>

* Transform of the entire scene (including the light sources).
* Better PCSS soft shadow

<p align="left">
  <img height="295" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F4J-ground-pcss.jpg"/>
</p>

* Ground shadow

<p align="left">
  <img height="298" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F4J-ground-front.jpg"/>
  <img height="294" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-4J-Ground.jpg"/>
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
* Bump (displacement) texture.
* <del>Normal texture.</del>
* <del>Direction of lgiht source.</del>
* <del>Intensity of light source.</del>
* <del>Mutilple light sources.</del>
* <del>Selectable list of object.</del>
* <del>Surface smooth.</del>
* Shadow
  * <del>Shadow to model</del>
  * <del>Shadow to ground.</del>
  * <del>PCSS.</del>
    * <del>Basic PCSS.</del>
    * <del>Adjustable occluder search range.</del>
    * <del>More adjustable bias.</del>
  * <del>Transparency (strength) of shadow overlay.</del> (Achieved by ambient)
  * Linear shadow map (more plausible PCSS, VSM).
  * Adaptive shadow map resolution/region.
* <del>Per light-source, per-surface shadow properties (bias, soft edge).</del>
* <del>Cull mode.</del>
* Surrounding.
  * <del>Cubmap skybox.</del>
  * Water (for ship model).
* <del>Motion blur (especially for rotating parts like rotor).</del>
* Detailed properties panel for indiviudal model parts.
  * <del>Smooth options (everywhere, texture discontinuiation only, etc).</del>
  * <del>Material opacity adjustment.
  * Material adjustment (specular, colors, etc).
  * List of board objects.
  * Self illumination.
* Reflection.
* <del>BRDF mode.</del>
* <del>Ambient occlusion.</del>
* Model visualization
  * <del>PCSS steps visualization.<del>
  * Triangle mesh
  * Normal/tangent visualization
  

## Early Screenshots

Screenshot of the first version (left). Add support to simple transparency (right).
<p align="left">
  <img height="200" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/ver0.0.jpg"/>
  <img height="200" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/ver0.0-transparency.jpg"/>
</p>


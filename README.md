# Nuo Model Viewer

A simple Wavefront OBJ viewer.

## Supported GPUs

* Intel HD serious GPUs are **not** supported. (Built-in integrated GPU in most models of Mac.)
* AMD Radeon Pro 560, and built-in descrete GPUs in almost all MacBook Pro later than 2017, are barely suppored. Their performance would be poor for the ray tracing rendering.
* AMD Radeon RX 580 or above is recommended, in particular but not limited to:
  * AMD Radeon RX Vega 56 is recommended.
  * AMD Radeon RX Vega 64, RX 5700, and so on, should be working, but untested.
  * AMD Radeon VII is highly recommended.
  * AMD Radeon Pro Vega II (Duo) (in the Mac Pro 2019). Acknowledge to @ibuick for the verification.

## Latest Update

* Specular lighting on a Fresnel surface.
* Multiple-importance sampling.
* Slider with adjustable scale.
* Full ray tracing.

<p align="left">
  <img width="800" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-35-ray-tracing-ground.jpg"/>
  <img width="800" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/indirect-light-spec.jpg"/>
</p>

* Hybrid rendering with ray tracing.
  * Direct lighting soft shadow.
  * Indirect lighting (ambient) with physically-based occlusion.
  * Physically based effect for the shadow overlay (blend-in with photographic scene).
  * Self-illuminating objects.
* Checkerboard background for better inspecting the result transparency.

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-35-ray_tracing.png"/>
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/AFD-ray-tracing.png"/>
</p>

<p align="left">
  <img width="400" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/LP670-checkerboard.png"/>
</p>

* Inspecting intremediate textures in debug.

<p align="left">
  <img width="600" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/Inspect.jpg"/>
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
  <img width="446" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/SDROBJ-no-occlusion.jpg"/>
</p>

* Transform of the entire scene (including the light sources).
* Better PCSS soft shadow

<p align="left">
  <img width="408" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F4J-ground-pcss.jpg"/>
</p>

* Ground shadow

<p align="left">
  <img width="448" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F4J-ground-front.jpg"/>
  <img width="388" src="https://github.com/middlefeng/NuoModelViewer/blob/master/screenshots/F-4J-Ground.jpg"/>
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

* <del>Order-independent transparency.</del>
* Bump (displacement) texture.
* Support PBRT format.
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
  * <del>Self illumination.</del>
* Ray tracing
  * <del>Faster buffer construction.</del>
  * <del>Ground reflection.</del>
  * <del>Specular term in direct lighting shadow, and in global illumniation.</del>
  * <del>Light source surface sampling.</del>
  * <del>Shadow ray visibility.</del>
  * Multiple importance sampling. Unified reflection model.
  * Normal map.
  * Specular map.
  * Translucent map.
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


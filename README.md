# Stable-Horde-Client-Addon

A Godot addon for using the [Stable Horde](https://stablehorde.net/) from Godot. It allows games to utilize free dynamic image generations using Stable Diffusion on a crowdsourced cluster.

Adding this Plugin will provide you with a StableHordeClient Node and class. This Node provides exported variables to fill in with the kind of generation you want to achieve from Stable Diffusion

# API Key

While you can use this plugin anonymously, by using the api_key '0000000000', depending on the load on the horde, this can take a while. If you [generate a unique api_key for yourself](https://stablehorde.net/register) you can use it to join the horde with your own PC and receive kudos for generating for others, which will increase your priority on the horde.

# Generating

When you call the generate function, it will use the exported variables you've provided to send the generation to the Stable Horde and wait for the reply.

You can also send an ad-hoc bypass prompt or parameters to the generate function, which will override the exported variables. When the generation is complete, The StableHordeClient will convert the image data into textures and send them with its `images_generated` signal. You can afterwards also find them again in its `latest_image_textures` and `all_image_textures` arrays.

# Demo

Run this project using the Demo scene. Press the button to keep generating new images into the grid

# To Do

Add the rest of the options for the generations
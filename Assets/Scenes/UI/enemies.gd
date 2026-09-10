## Script for the HUD's "Enemies:" counter label.
##
## Intentionally empty: the label's text is driven from the outside by
## hud.gd's _process(), which writes map.mobAmount into it every frame. The
## script exists only so the node has one attached if per-label behaviour is
## ever needed here.
extends Label

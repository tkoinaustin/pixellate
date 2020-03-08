# Pixellate

## About the App
I had a project for work in which I needed to blur out or obfuscate portions of a photograph. This would be for privacy concerns so the there would be no personably identifiable information present available for the public to see. 

When I first looked into the project, I had built an erasure where the portion of the picture that was selected would be blotted out with a black circle. Then I needed to save that info into the original picture, which required some lower level API's which manipulated image contexts. 

When 
ux got a look, they insisted that we pixellate the image rather than just black it out. That turned into a whole other can of worms. Core Image has hundreds of great filters, including a pixellate filter. Problem is, they all operate on the whole image, not just a section.

I ended up adding a layer to the image view. That layer contained the original image run through the pixellate filter. Then I added a masking layer to the pixellated layer. The entire pixellated layer was masked out, so only the original image showed through. I then added touch events to collect the path traced on the picture and added a line to the masking layer where the user traced. This mask then would show the pixellated version of the photo, giving the impression you were pixellating the picture as you trace your finger. 

Ultimately, the UX team was happy, so everyone was happy!

 
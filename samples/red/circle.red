Red [ 
	needs: 'view
]

print "Hello"
view [
        sld: slider return
        base 200x200 
            draw  [circle 100x100 5]
            react [face/draw/3: to integer! 100 * sld/data]
    ]

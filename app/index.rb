doc = JS.global[:document]
body = doc[:body]

# Créer un nouvel élément div
output_div = doc.createElement('div')
output_div[:id] = 'output'

# Ajouter la div au body
body.appendChild(output_div)

# Maintenant vous pouvez la sélectionner et modifier son contenu
output = doc.getElementById('output')
output[:innerHTML] = "<h1>Hello from unified code! from atome</h1><h2>#{Time.now}</h2>"
JS.global[:console].log("Message in the console")

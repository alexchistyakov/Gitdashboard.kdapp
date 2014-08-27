[NOT_CLONED,CLONING,CLONED,LOADING] = [0...3]
searchKeywords = ["3D Modeling","Data Visualization","Game Engines","Software Development tools","Design Essentials","Package Manager","CSS Preprocessors"]
searchResultCount = 50
reposInTrending = 50
reposPerTopic = 10
maxSymbolsInDescription = 100

dataPath = "~/.gitdashboard/repodata"
oauthKey = "D6R6uhEmh7kmXCVT9YzSwvHP-tk"

#A little fix for CoffeeScripts scoping problems
root = exports ? this
root.directoryExists = false
root.repodata = {}

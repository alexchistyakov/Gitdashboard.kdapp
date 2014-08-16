flatten = (matrix)->
    res = []
    for array in matrix
        for element in array
            res.push element
    res
bubbleSort = (array)->
    modified = array.slice()
    for i in [0...modified.length - 1]
        for j in [0...modified.length - 1 - i] when modified[j].options.stars < modified[j + 1].options.stars
            [modified[j], modified[j+1]] = [modified[j + 1], modified[j]]
    return modified
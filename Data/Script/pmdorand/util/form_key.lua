local template = '%s/%d'

return function(identifier, form)
    return template:format(identifier, form)
end

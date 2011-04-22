root = exports ? this

mongoose = require 'mongoose'
sys = require 'sys'
Schema = mongoose.Schema
Mongoose = mongoose.Mongoose

root.createModel = (db) ->
    personSchema = new Schema(
        title:
            type: String
            required: true
        age:
            type: Number
            min: 5
            max: 20
        meta:
            likes : [String],
            birth : { type: Date, default: Date.now }
    )

    mongoose.model 'Person', personSchema
    root.Person = db.model 'Person'

/*!
 * Based on jQuery JavaScript Library v1.5.2
 * http://jquery.com/
 *
 * Copyright 2011, John Resig
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * Includes Sizzle.js
 * http://sizzlejs.com/
 * Copyright 2011, The Dojo Foundation
 * Released under the MIT, BSD, and GPL Licenses.
 *
 * Date: Thu Mar 31 15:28:23 2011 -0400
 */

class2type = {};

type = function( obj ) {
    return obj == null ?
        String(obj) : class2type[ toString.call(obj) ] || "object";
};

typeList = "Boolean Number String Function Array Date RegExp Object".split(" ")

for (var i in typeList) {
    var name = typeList[i];
    class2type[ "[object " + name + "]" ] = name.toLowerCase();
};

isFunction = function (obj) {
    return type(obj) === "function";
};

isArray = Array.isArray || function (obj) {
    return type(obj) === "array";
};

hasOwn = Object.prototype.hasOwnProperty;

isPlainObject = function (obj) {
    // Must be an Object.
    // Because of IE, we also have to check the presence of the constructor property.
    // Make sure that DOM nodes and window objects don't pass through, as well
    if (!obj || type(obj) !== "object" || obj.nodeType) {
	return false;
    } 

    // Not own constructor property must be Object
    if (obj.constructor &&
        !hasOwn.call(obj, "constructor") &&
        !hasOwn.call(obj.constructor.prototype, "isPrototypeOf") ) {
        return false;
    }

    // Own properties are enumerated firstly, so to speed up,
    // if last one is own, then all properties are own.
    var key;
    for (key in obj) {}

    return key === undefined || hasOwn.call(obj, key);
};


extend = function() {
	var options, name, src, copy, copyIsArray, clone,
		target = arguments[0] || {},
		i = 1,
		length = arguments.length,
		deep = false;

	// Handle a deep copy situation
	if ( typeof target === "boolean" ) {
		deep = target;
		target = arguments[1] || {};
		// skip the boolean and the target
		i = 2;
	}

	// Handle case when target is a string or something (possible in deep copy)
	if ( typeof target !== "object" && !isFunction(target) ) {
		target = {};
	}

	// originally: extend jQuery itself if only one argument is passed
        // now make a clone
	if (length === i) {
		target = {};
		--i;
	}

	for ( ; i < length; i++ ) {
		// Only deal with non-null/undefined values
		if ((options = arguments[i]) != null ) {
			// Extend the base object
			for ( name in options ) {
				src = target[ name ];
				copy = options[ name ];

				// Prevent never-ending loop
				if ( target === copy ) {
					continue;
				}

				// Recurse if we're merging plain objects or arrays
				if ( deep && copy && (isPlainObject(copy) || (copyIsArray = isArray(copy)) ) ) {
					if ( copyIsArray ) {
						copyIsArray = false;
						clone = src && isArray(src) ? src : [];

					} else {
						clone = src && isPlainObject(src) ? src : {};
					}

					// Never move original objects, clone them
					target[ name ] = extend(deep, clone, copy);

				// Don't bring in undefined values
				} else if ( copy !== undefined ) {
					target[ name ] = copy;
				}
			}
		}
	}

	// Return the modified object
	return target;
};

exports.extend = extend;
exports.isArray = isArray;
exports.isFunction = isFunction;
exports.isPlainObject = isPlainObject;
exports.deepCopy = function (source) {
    return extend(true, {}, source);
};
exports.shallowCopy = function (source) {
    return extend({}, source);
};
exports.getType = type;

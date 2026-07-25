struct Lens {
    get,
    set
}

fun lens(get, set) => Lens { get: get, set: set }


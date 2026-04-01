def is_valid_scene(scene):
    try:
        if not scene.get("action"):
            return False
        if not scene.get("characters"):
            return False
        if not scene.get("setting"):
            return False
        return True
    except:
        return False

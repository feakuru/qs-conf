import psutil

print(int(psutil.virtual_memory().percent))

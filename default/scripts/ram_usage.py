import psutil

if __name__ == "__main__":
    print(int(psutil.virtual_memory().percent))

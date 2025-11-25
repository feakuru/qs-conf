import psutil

if __name__ == "__main__":
    print(f"{int(psutil.cpu_percent(interval=0.1)):2d}", end="")

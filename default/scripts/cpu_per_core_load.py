import psutil

if __name__ == "__main__":
    print(
        " ".join(
            str(int(val))
            for val in psutil.cpu_percent(
                percpu=True,
                interval=0.1,
            )
        )
    )

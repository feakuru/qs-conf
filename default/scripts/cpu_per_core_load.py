import psutil

print(
    " ".join(
        str(int(val))
        for val in psutil.cpu_percent(
            percpu=True,
            interval=0.1,
        )
    )
)

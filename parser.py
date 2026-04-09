import os
from PIL import Image
import imageio.v2 as imageio

# Папка с MP4 файлами
input_folder = "assets/stickers/animals"   # <-- положи сюда все mp4
# Папка для WebP
output_folder = "assets/stickers/animals_webp"
os.makedirs(output_folder, exist_ok=True)

# Настройки
FPS_REDUCTION = 2   # оставляем каждый 2-й кадр, чтобы уменьшить размер
SCALE = 0.6         # уменьшаем разрешение до 60%
QUALITY = 60        # качество WebP (0-100)

for file_name in os.listdir(input_folder):
    if file_name.lower().endswith(".mp4"):
        input_path = os.path.join(input_folder, file_name)
        output_path = os.path.join(output_folder, os.path.splitext(file_name)[0] + ".webp")
        try:
            reader = imageio.get_reader(input_path)
            fps = reader.get_meta_data().get('fps', 24)
            frames = []

            for i, frame in enumerate(reader):
                if i % FPS_REDUCTION != 0:
                    continue
                img = Image.fromarray(frame)
                img = img.resize((int(img.width * SCALE), int(img.height * SCALE)))
                frames.append(img)

            if frames:
                duration = int(1000 / (fps / FPS_REDUCTION))
                frames[0].save(
                    output_path,
                    save_all=True,
                    append_images=frames[1:],
                    duration=duration,
                    loop=0,
                    format="WEBP",
                    quality=QUALITY,
                    method=6
                )
                print(f"Конвертировано: {file_name} -> {output_path}")
        except Exception as e:
            print(f"Ошибка при обработке {file_name}: {e}")

print("Конвертация завершена!")
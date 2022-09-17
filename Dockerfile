FROM rocm/pytorch:rocm5.2.3_ubuntu20.04_py3.7_pytorch_1.12.1

SHELL ["/bin/bash", "-c"]

COPY . /root/stable-diffusion

# Create the environment
RUN cd /root/stable-diffusion \
 && conda env create -f environment.yaml

# Initialize conda in bash config files
RUN conda init bash

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "ldm", "/bin/bash", "-c"]

# Replace environment's pytorch with ROCm compatible version and install gradio for the GUI
RUN pip install --upgrade torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/rocm5.1.1 \
 && pip install gradio

# Set necessary exports for Stable Diffusion to work on RDNA/RDNA2 cards using ROCm
ENV HSA_OVERRIDE_GFX_VERSION=10.3.0

VOLUME /root/.cache
VOLUME /data
VOLUME /output

ENV PYTHONUNBUFFERED=1
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860
EXPOSE 7860

RUN ln -s /data /root/stable-diffusion/models/ldm/stable-diffusion-v1 \
 && ln -s /outputs /root/stable-diffusion

WORKDIR /root/stable-diffusion

# Conda should activate the environment by default (eg: if a user opens a bash shell into running container)
RUN echo "conda activate ldm" >> ~/.bashrc

ENTRYPOINT ["conda", "run", "-n", "ldm", "python", "optimizedSD/txt2img_gradio.py"]
# ENTRYPOINT ["conda", "run", "-n", "ldm", "python", "optimizedSD/img2img_gradio.py"]
# ENTRYPOINT ["conda", "run", "-n", "ldm", "python", "optimizedSD/inpaint_gradio.py"]
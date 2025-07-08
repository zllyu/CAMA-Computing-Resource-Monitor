import torch
import time

def occupy_gpu(device_id=0, tensor_size=(256, 1024, 1024)):
    """
    Allocate a tensor on GPU to occupy memory.

    Args:
        device_id (int): GPU index.
        tensor_size (tuple): Size of tensor to allocate.
    """
    device = torch.device(f"cuda:{device_id}")
    print(f"Allocating tensor of shape {tensor_size} on {device}...")
    
    # Allocate tensor
    tensor = torch.empty(tensor_size, dtype=torch.float32, device=device)

    # Optionally fill it to make sure it's really allocated
    tensor.fill_(1.0)
    print(f"Tensor allocated. Holding GPU memory...")

    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        print("Exiting and releasing GPU memory.")

if __name__ == "__main__":
    occupy_gpu()


import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "scripts"))
import aes_trace

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="AES-128 Interactive Submodule Visualizer")
    parser.add_argument("--key", type=str, default="", help="128-bit hex key (32 hex chars)")
    parser.add_argument("--input", type=str, default="", help="128-bit hex input block (32 hex chars)")
    parser.add_argument("--decrypt", action="store_true", help="Run decryption instead of encryption")
    args = parser.parse_args()
    
    key = args.key.strip()
    data = args.input.strip()
    
    if not key or not data:
        print("\n=== AES-128 Interactive Submodule Visualizer ===")
        print("Press ENTER to use official NIST FIPS-197 Appendix B vectors, or type custom 32-char hex.\n")
        
        if not key:
            default_key = "2b7e151628aed2a6abf7158809cf4f3c"
            try:
                user_key = input(f"Enter Key (32 hex) [default: {default_key}]: ").strip()
                key = user_key if user_key else default_key
            except (EOFError, KeyboardInterrupt):
                key = default_key
                
        if not data:
            default_data = "3243f6a8885a308d313198a2e0370734"
            try:
                user_data = input(f"Enter Data (32 hex) [default: {default_data}]: ").strip()
                data = user_data if user_data else default_data
            except (EOFError, KeyboardInterrupt):
                data = default_data
                
    aes_trace.run_trace(key, data, decrypt=args.decrypt)

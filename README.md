# A basic rain example in Raylib (Zig)

## This has been optimized for performance.

- I went from 42% CPU usage to 18% CPU usage and from 68% GPU usage till 20% GPU usage.
- **How?** Initially the rain was happening from in a (500 x 500 x 5 grid of rain drops) x 2 (because 2 layers are being rendered at a time) which means in total: ~2500000 drops being rendered every second which costed 42% CPU and 68% GPU on a mac book M2 Air. (which is too much for a basic raylib game).
- I first optimized the variable types from f32 -> u8 (where ever necessary), which did reduce the memory usage but didn't do much to GPU/CPU usage.
- It wasn't enough obviously, I saw there were two issues at this time:
    - The rain only happened between those 500 blocks and not wherever you go.
    - The performance issue.
- So, I thought of a plan, why not create rain only 10 x 10 x 2 block directly at the first person camera?
- So, I did that, hence I heavily improved performance now, I read 17% CPU usage and only 20% gpu usage even while playing the game along with 100mb of ram.

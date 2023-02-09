use image::*;
use rand::prelude::*;
use rand::distributions::Alphanumeric;
use rayon::prelude::*;
use std::iter;
use std::path::{PathBuf};
use structopt::StructOpt;
use rand::rngs::StdRng;
use std::fs::File;
use std::io::Write;
use std::fs::create_dir_all;


#[derive(StructOpt, Debug)]
struct Options {
    #[structopt(short = "o", long = "output-dir", default_value = "./_Directory", parse(from_os_str))]
    output_directory: PathBuf,

    #[structopt(name = "COUNT", default_value = "1")]
    count: u64,
}

fn main() {

    create_dir_all("./_Directory").unwrap(); // creates directory if it doesn't exist

    let options = Options::from_args(); // get student id number for seeding rand
    let file_count = 500; // number of files to create
    //println!("Generating {} random files", file_count);

    (0..file_count).into_par_iter().for_each(|i| {
        let mut rng = StdRng::seed_from_u64(options.count*i/17);
        let mut path = options.output_directory.clone();
        let index = rng.gen_range(0,6);
        let file_extensions = vec!{".jpg",".bmp",".ico",".png",".txt",".dat"};
        let filename = gen_filename(&mut rng,file_extensions[index]);
        //println!("  [{}/{}] {}", i + 1, file_count, filename);
        path.push(filename);

        if file_extensions[index] != ".txt" && file_extensions[index] != ".dat"{
          let buf = gen_image(&mut rng, &options);

       	   if let Err(e) = buf.save(path) {
              println!("error: {}", e);
            }
        }
        else if file_extensions[index] == ".txt"
		{
			gen_text_file(path,rng);
        }
        else if file_extensions[index] == ".dat"
        {
            gen_dat_file(path,rng);
        }
    });
}

fn gen_filename(mut rng: impl RngCore, extension: &str) -> String {
    let length = rng.gen_range(4, 128);
    let mut name = String::with_capacity(length + extension.len());

    for c in iter::repeat(()).map(|_| rng.sample(Alphanumeric)).take(length) {
        name.push(c);
    }

    name.push_str(extension);

    name
}

fn gen_image(mut rng: impl RngCore, _options: &Options) -> ImageBuffer<Rgb<u8>, Vec<u8>>  {
    let width = rng.gen_range(1, 256);
    let height = rng.gen_range(1, 256);

    let mut buf = image::ImageBuffer::new(width, height);

    for (_, _, pixel) in buf.enumerate_pixels_mut() {
        *pixel = image::Rgb {
            data: [rng.gen_range(0, 255), rng.gen_range(0, 255), rng.gen_range(0, 255)],
        };
    }

    buf
}

fn gen_text_file(path: PathBuf, mut rng: impl RngCore){
    let mut file  = File::create(&path).unwrap();
    let length = rng.gen_range(4, 256);

    let mut data = String::with_capacity(length);

    for c in iter::repeat(()).map(|_| rng.sample(Alphanumeric)).take(length) {
        data.push(c);
    }
    file.write_all(data.as_bytes()).unwrap();
}

fn gen_dat_file(path: PathBuf, mut rng: impl RngCore){
    let mut file  = File::create(&path).unwrap();
    let size = rng.gen_range(0,1024);
    let mut random_bytes = vec![0u8; size as usize];
    rng.fill_bytes(&mut random_bytes);
    file.write_all(&random_bytes).unwrap();
}

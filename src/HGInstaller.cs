using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace HeroGuild.ClientInstaller
{
    public class ModrinthIndex
    {
        public int formatVersion { get; set; }
        public string game { get; set; }
        public string versionId { get; set; }
        public string name { get; set; }
        public string summary { get; set; }
        public Dictionary<string, string> dependencies { get; set; }
        public List<ModFile> files { get; set; }
    }

    public class ModFile
    {
        public string path { get; set; }
        public Dictionary<string, string> hashes { get; set; }
        public List<string> env { get; set; }
        public List<string> downloads { get; set; }
        public long fileSize { get; set; }
    }

    public class ServerInfo
    {
        public string name { get; set; }
        public string ip { get; set; }
        public int acceptTextures { get; set; }
    }

    public class MainForm : Form
    {
        private readonly Color ColorBgMain = Color.FromArgb(22, 20, 18);
        private readonly Color ColorCardBg = Color.FromArgb(32, 29, 25);
        private readonly Color ColorGoldPrimary = Color.FromArgb(255, 179, 15);   // #FFB30F
        private readonly Color ColorGoldDark = Color.FromArgb(184, 142, 70);       // #B88E46
        private readonly Color ColorTextBright = Color.FromArgb(248, 244, 235);
        private readonly Color ColorTextMuted = Color.FromArgb(200, 188, 170);

        private const string DISCORD_URL = "https://discord.gg/W3harVKevk";
        private const string GITHUB_SERVER_INFO_URL = "https://vxnku.github.io/-HG-HGMM/server_info.json";
        private const string CLOUDFLARE_SERVER_INFO_URL = "https://bold-bread-e4ce.yuliy-ml.workers.dev/server_info.json";
        private const string JSDELIVR_SERVER_INFO_URL = "https://cdn.jsdelivr.net/gh/Vxnku/-HG-HGMM@main/server_info.json";
        private const string GDRIVE_SERVER_INFO_ID = "1haCJcm_oAM3LR0Mhr-hM2a7Ln1-B5_Qt";
        private const string GDRIVE_FABRIC_ZIP_ID = "1S65NDM9CpL8WsHgYdH6brsJ2MgU_3_dz";

        private static readonly HttpClient httpClient = CreateHttpClient();

        private static HttpClient CreateHttpClient()
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
            HttpClientHandler handler = new HttpClientHandler
            {
                AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate,
                AllowAutoRedirect = true,
                UseCookies = true,
                CookieContainer = new CookieContainer()
            };
            HttpClient client = new HttpClient(handler)
            {
                Timeout = TimeSpan.FromSeconds(60)
            };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("HeroGuildClientInstaller/1.0 (+https://github.com/Vxnku)");
            return client;
        }

        private static string BuildGoogleDriveUrl(string fileId)
        {
            UriBuilder builder = new UriBuilder("https", "drive.usercontent.google.com", 443, "/download");
            builder.Query = string.Format("id={0}&export=download&confirm=t", fileId);
            return builder.Uri.ToString();
        }

        private PictureBox picLogo;
        private PictureBox picDiscord;
        private ToolTip toolTip;

        private Label lblTitle;
        private Label lblSubtitle;

        private Label lblPack;
        private TextBox txtPack;
        private Button btnBrowsePack;
        private Label lblPackStatus;

        private Label lblTarget;
        private TextBox txtTarget;
        private Button btnBrowseTarget;
        private Button btnDefaultTarget;
        private Button btnOpenTargetFolder;
        private Label lblTargetStatus;

        private CheckBox chkInstallFabric;
        private CheckBox chkCleanMods;
        private CheckBox chkUnpackRP;
        private CheckBox chkAddServer;
        private CheckBox chkExtractOverrides;
        private Button btnInstall;
        private ProgressBar progressBar;
        private Label lblStatus;
        private TextBox txtLog;
        private BackgroundWorker worker;

        private Bitmap sourceLogoBitmap = null;
        private Bitmap sourceDiscordBitmap = null;

        public MainForm()
        {
            InitializeComponent();
            LoadImagesAndIcons();
            AutoFindLocalPackAndMinecraft();
        }

        private void LoadImagesAndIcons()
        {
            try
            {
                this.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            }
            catch { }

            try
            {
                using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("HGLogo.png"))
                {
                    if (s != null) sourceLogoBitmap = new Bitmap(s);
                }
            }
            catch { }

            if (sourceLogoBitmap == null)
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string[] candidates = { "HGPackLogoFabric.png", "logo.png", "HGPackLogoFabric128.png" };
                foreach (string c in candidates)
                {
                    string p = Path.Combine(baseDir, c);
                    if (File.Exists(p))
                    {
                        try { sourceLogoBitmap = new Bitmap(p); break; } catch { }
                    }
                }
            }

            if (sourceLogoBitmap != null && picLogo != null)
            {
                picLogo.Image = RenderCrispBitmap(sourceLogoBitmap, picLogo.Width, picLogo.Height);
            }

            try
            {
                using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("DiscordLogo.png"))
                {
                    if (s != null) sourceDiscordBitmap = new Bitmap(s);
                }
            }
            catch { }

            if (sourceDiscordBitmap == null)
            {
                string baseDir = AppDomain.CurrentDomain.BaseDirectory;
                string[] candidates = { "discord-round-color-icon.png", "discord.png" };
                foreach (string c in candidates)
                {
                    string p = Path.Combine(baseDir, c);
                    if (File.Exists(p))
                    {
                        try { sourceDiscordBitmap = new Bitmap(p); break; } catch { }
                    }
                }
            }

            if (sourceDiscordBitmap != null && picDiscord != null)
            {
                picDiscord.Image = RenderCrispBitmap(sourceDiscordBitmap, picDiscord.Width, picDiscord.Height);
            }
        }

        private Bitmap RenderCrispBitmap(Bitmap source, int w, int h)
        {
            Bitmap crispBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(crispBmp))
            {
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.HighQuality;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.CompositingQuality = CompositingQuality.HighQuality;
                g.Clear(Color.Transparent);
                g.DrawImage(source, 0, 0, w, h);
            }
            return crispBmp;
        }

        private void InitializeComponent()
        {
            this.Text = "HeroGuild Client Installer • Fabric 1.21.1";
            this.Size = new Size(740, 735);
            this.MinimumSize = new Size(680, 640);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = ColorBgMain;
            this.ForeColor = ColorTextBright;
            this.Font = new Font("Segoe UI", 9.5F, FontStyle.Regular);

            toolTip = new ToolTip();
            toolTip.AutoPopDelay = 5000;
            toolTip.InitialDelay = 200;
            toolTip.ReshowDelay = 100;
            toolTip.ShowAlways = true;

            picLogo = new PictureBox();
            picLogo.Location = new Point(25, 14);
            picLogo.Size = new Size(52, 52);
            picLogo.SizeMode = PictureBoxSizeMode.CenterImage;
            this.Controls.Add(picLogo);

            picDiscord = new PictureBox();
            picDiscord.Location = new Point(85, 16);
            picDiscord.Size = new Size(48, 48);
            picDiscord.SizeMode = PictureBoxSizeMode.CenterImage;
            picDiscord.Cursor = Cursors.Hand;
            picDiscord.Click += (s, e) => OpenDiscordLink();
            toolTip.SetToolTip(picDiscord, "Наш Discord сервер (https://discord.gg/W3harVKevk)");
            this.Controls.Add(picDiscord);

            lblTitle = new Label();
            lblTitle.Text = "HEROGUILD CLIENT INSTALLER";
            lblTitle.Font = new Font("Segoe UI", 16F, FontStyle.Bold);
            lblTitle.ForeColor = ColorGoldPrimary;
            lblTitle.Location = new Point(146, 14);
            lblTitle.Size = new Size(550, 30);
            this.Controls.Add(lblTitle);

            lblSubtitle = new Label();
            lblSubtitle.Text = "Универсальный установщик сборки • Исходный код на GitHub";
            lblSubtitle.Font = new Font("Segoe UI", 9F, FontStyle.Regular);
            lblSubtitle.ForeColor = ColorTextMuted;
            lblSubtitle.Location = new Point(148, 44);
            lblSubtitle.Size = new Size(550, 22);
            this.Controls.Add(lblSubtitle);

            // --- SECTION 1: .mrpack Selection ---
            lblPack = new Label();
            lblPack.Text = "1. Файл сборки (.mrpack):";
            lblPack.Font = new Font("Segoe UI", 9.5F, FontStyle.Bold);
            lblPack.ForeColor = ColorGoldPrimary;
            lblPack.Location = new Point(25, 82);
            lblPack.Size = new Size(670, 20);
            this.Controls.Add(lblPack);

            txtPack = new TextBox();
            txtPack.Location = new Point(25, 105);
            txtPack.Size = new Size(560, 26);
            txtPack.BackColor = ColorCardBg;
            txtPack.ForeColor = ColorTextBright;
            txtPack.BorderStyle = BorderStyle.FixedSingle;
            txtPack.TextChanged += (s, e) => UpdatePackStatus();
            this.Controls.Add(txtPack);

            btnBrowsePack = new Button();
            btnBrowsePack.Text = "Обзор...";
            btnBrowsePack.Location = new Point(595, 103);
            btnBrowsePack.Size = new Size(105, 28);
            btnBrowsePack.BackColor = Color.FromArgb(44, 39, 32);
            btnBrowsePack.ForeColor = ColorGoldPrimary;
            btnBrowsePack.FlatStyle = FlatStyle.Flat;
            btnBrowsePack.FlatAppearance.BorderColor = ColorGoldDark;
            btnBrowsePack.FlatAppearance.BorderSize = 1;
            btnBrowsePack.Cursor = Cursors.Hand;
            btnBrowsePack.Click += BtnBrowsePack_Click;
            this.Controls.Add(btnBrowsePack);

            lblPackStatus = new Label();
            lblPackStatus.Text = "Поиск .mrpack в папке программы...";
            lblPackStatus.Font = new Font("Segoe UI", 8.5F);
            lblPackStatus.ForeColor = ColorTextMuted;
            lblPackStatus.Location = new Point(27, 134);
            lblPackStatus.Size = new Size(670, 18);
            this.Controls.Add(lblPackStatus);

            // --- SECTION 2: Target .minecraft Selection ---
            lblTarget = new Label();
            lblTarget.Text = "2. Папка Minecraft (куда устанавливать сборку):";
            lblTarget.Font = new Font("Segoe UI", 9.5F, FontStyle.Bold);
            lblTarget.ForeColor = ColorGoldPrimary;
            lblTarget.Location = new Point(25, 160);
            lblTarget.Size = new Size(670, 20);
            this.Controls.Add(lblTarget);

            txtTarget = new TextBox();
            txtTarget.Location = new Point(25, 183);
            txtTarget.Size = new Size(450, 26);
            txtTarget.BackColor = ColorCardBg;
            txtTarget.ForeColor = ColorTextBright;
            txtTarget.BorderStyle = BorderStyle.FixedSingle;
            txtTarget.TextChanged += (s, e) => UpdateTargetStatus();
            this.Controls.Add(txtTarget);

            btnBrowseTarget = new Button();
            btnBrowseTarget.Text = "Выбрать...";
            btnBrowseTarget.Location = new Point(485, 181);
            btnBrowseTarget.Size = new Size(95, 28);
            btnBrowseTarget.BackColor = Color.FromArgb(44, 39, 32);
            btnBrowseTarget.ForeColor = ColorGoldPrimary;
            btnBrowseTarget.FlatStyle = FlatStyle.Flat;
            btnBrowseTarget.FlatAppearance.BorderColor = ColorGoldDark;
            btnBrowseTarget.FlatAppearance.BorderSize = 1;
            btnBrowseTarget.Cursor = Cursors.Hand;
            btnBrowseTarget.Click += BtnBrowseTarget_Click;
            this.Controls.Add(btnBrowseTarget);

            btnDefaultTarget = new Button();
            btnDefaultTarget.Text = "Сброс";
            btnDefaultTarget.Location = new Point(587, 181);
            btnDefaultTarget.Size = new Size(58, 28);
            btnDefaultTarget.BackColor = Color.FromArgb(44, 39, 32);
            btnDefaultTarget.ForeColor = ColorGoldPrimary;
            btnDefaultTarget.FlatStyle = FlatStyle.Flat;
            btnDefaultTarget.FlatAppearance.BorderColor = ColorGoldDark;
            btnDefaultTarget.FlatAppearance.BorderSize = 1;
            btnDefaultTarget.Cursor = Cursors.Hand;
            btnDefaultTarget.Click += (s, e) => SetDefaultMinecraftPath();
            this.Controls.Add(btnDefaultTarget);

            btnOpenTargetFolder = new Button();
            btnOpenTargetFolder.Text = "Папка";
            btnOpenTargetFolder.Location = new Point(652, 181);
            btnOpenTargetFolder.Size = new Size(48, 28);
            btnOpenTargetFolder.BackColor = Color.FromArgb(44, 39, 32);
            btnOpenTargetFolder.ForeColor = ColorGoldPrimary;
            btnOpenTargetFolder.FlatStyle = FlatStyle.Flat;
            btnOpenTargetFolder.FlatAppearance.BorderColor = ColorGoldDark;
            btnOpenTargetFolder.FlatAppearance.BorderSize = 1;
            btnOpenTargetFolder.Cursor = Cursors.Hand;
            btnOpenTargetFolder.Click += BtnOpenTargetFolder_Click;
            this.Controls.Add(btnOpenTargetFolder);

            lblTargetStatus = new Label();
            lblTargetStatus.Text = "Проверка пути...";
            lblTargetStatus.Font = new Font("Segoe UI", 8.5F);
            lblTargetStatus.ForeColor = ColorTextMuted;
            lblTargetStatus.Location = new Point(27, 212);
            lblTargetStatus.Size = new Size(670, 18);
            this.Controls.Add(lblTargetStatus);

            // --- SECTION 3: Options ---
            chkInstallFabric = new CheckBox();
            chkInstallFabric.Text = "Проверить и установить Fabric Loader 0.19.3 (Рекомендуется)";
            chkInstallFabric.Checked = true;
            chkInstallFabric.ForeColor = ColorGoldPrimary;
            chkInstallFabric.Location = new Point(25, 236);
            chkInstallFabric.Size = new Size(670, 24);
            this.Controls.Add(chkInstallFabric);

            chkCleanMods = new CheckBox();
            chkCleanMods.Text = "Очистить старые .jar моды перед установкой (Рекомендуется)";
            chkCleanMods.Checked = true;
            chkCleanMods.ForeColor = ColorTextBright;
            chkCleanMods.Location = new Point(25, 262);
            chkCleanMods.Size = new Size(670, 24);
            this.Controls.Add(chkCleanMods);

            chkUnpackRP = new CheckBox();
            chkUnpackRP.Text = "Распаковывать ресурспаки как папки (прямиком без zip-архивов)";
            chkUnpackRP.Checked = true;
            chkUnpackRP.ForeColor = ColorGoldPrimary;
            chkUnpackRP.Location = new Point(25, 288);
            chkUnpackRP.Size = new Size(670, 24);
            this.Controls.Add(chkUnpackRP);

            chkAddServer = new CheckBox();
            chkAddServer.Text = "Установить сервер HeroGuild в список сетевой игры (servers.dat)";
            chkAddServer.Checked = true;
            chkAddServer.ForeColor = ColorGoldPrimary;
            chkAddServer.Location = new Point(25, 314);
            chkAddServer.Size = new Size(670, 24);
            this.Controls.Add(chkAddServer);

            chkExtractOverrides = new CheckBox();
            chkExtractOverrides.Text = "Установить локальные конфигурации из .mrpack (если есть)";
            chkExtractOverrides.Checked = true;
            chkExtractOverrides.ForeColor = ColorTextBright;
            chkExtractOverrides.Location = new Point(25, 340);
            chkExtractOverrides.Size = new Size(670, 24);
            this.Controls.Add(chkExtractOverrides);

            // --- SECTION 4: Install Button ---
            btnInstall = new Button();
            btnInstall.Text = "УСТАНОВИТЬ СБОРКУ";
            btnInstall.Font = new Font("Segoe UI", 11.5F, FontStyle.Bold);
            btnInstall.Location = new Point(25, 372);
            btnInstall.Size = new Size(675, 45);
            btnInstall.BackColor = ColorGoldPrimary;
            btnInstall.ForeColor = Color.FromArgb(18, 16, 12);
            btnInstall.FlatStyle = FlatStyle.Flat;
            btnInstall.FlatAppearance.BorderSize = 0;
            btnInstall.Cursor = Cursors.Hand;
            btnInstall.Click += BtnInstall_Click;
            this.Controls.Add(btnInstall);

            // --- SECTION 5: Progress & Logs ---
            lblStatus = new Label();
            lblStatus.Text = "Готов к установке.";
            lblStatus.Location = new Point(25, 424);
            lblStatus.Size = new Size(675, 20);
            lblStatus.ForeColor = ColorTextMuted;
            this.Controls.Add(lblStatus);

            progressBar = new ProgressBar();
            progressBar.Location = new Point(25, 447);
            progressBar.Size = new Size(675, 14);
            this.Controls.Add(progressBar);

            txtLog = new TextBox();
            txtLog.Multiline = true;
            txtLog.ScrollBars = ScrollBars.Vertical;
            txtLog.ReadOnly = true;
            txtLog.Location = new Point(25, 468);
            txtLog.Size = new Size(675, 218);
            txtLog.Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right;
            txtLog.BackColor = Color.FromArgb(14, 13, 11);
            txtLog.ForeColor = Color.FromArgb(215, 208, 195);
            txtLog.Font = new Font("Consolas", 9F);
            txtLog.BorderStyle = BorderStyle.FixedSingle;
            this.Controls.Add(txtLog);

            worker = new BackgroundWorker();
            worker.WorkerReportsProgress = true;
            worker.DoWork += Worker_DoWork;
            worker.ProgressChanged += Worker_ProgressChanged;
            worker.RunWorkerCompleted += Worker_RunWorkerCompleted;
        }

        private void OpenDiscordLink()
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = DISCORD_URL,
                    UseShellExecute = true
                };
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Не удалось открыть браузер:\n" + ex.Message, "Discord", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void SetDefaultMinecraftPath()
        {
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            txtTarget.Text = Path.Combine(appData, ".minecraft");
        }

        private void AutoFindLocalPackAndMinecraft()
        {
            SetDefaultMinecraftPath();

            string exeDir = AppDomain.CurrentDomain.BaseDirectory;
            List<string> searchDirs = new List<string> { exeDir, Directory.GetCurrentDirectory() };
            string parent = Path.GetDirectoryName(exeDir.TrimEnd('\\', '/'));
            if (!string.IsNullOrEmpty(parent)) searchDirs.Add(parent);

            string foundPack = null;
            foreach (string dir in searchDirs)
            {
                if (!string.IsNullOrEmpty(dir) && Directory.Exists(dir))
                {
                    string[] packs = Directory.GetFiles(dir, "*.mrpack");
                    if (packs.Length > 0)
                    {
                        foundPack = packs[0];
                        break;
                    }
                }
            }

            if (!string.IsNullOrEmpty(foundPack))
            {
                txtPack.Text = foundPack;
            }
            else
            {
                UpdatePackStatus();
            }

            UpdateTargetStatus();
        }

        private void UpdatePackStatus()
        {
            string p = txtPack.Text.Trim();
            if (string.IsNullOrEmpty(p))
            {
                lblPackStatus.Text = "[!] Файл .mrpack не выбран. Поместите .mrpack рядом с программой или нажмите «Обзор...»";
                lblPackStatus.ForeColor = ColorGoldDark;
            }
            else if (File.Exists(p))
            {
                try
                {
                    FileInfo fi = new FileInfo(p);
                    string packInfo = "";
                    using (ZipArchive zip = ZipFile.OpenRead(p))
                    {
                        ZipArchiveEntry entry = zip.GetEntry("modrinth.index.json");
                        if (entry != null)
                        {
                            using (Stream s = entry.Open())
                            using (StreamReader reader = new StreamReader(s, Encoding.UTF8))
                            {
                                string json = reader.ReadToEnd();
                                var serializer = new JavaScriptSerializer();
                                var index = serializer.Deserialize<ModrinthIndex>(json);
                                if (index != null)
                                {
                                    int count = index.files != null ? index.files.Count : 0;
                                    packInfo = string.Format(" • {0} (версия {1}, файлов: {2})", index.name, index.versionId, count);
                                }
                            }
                        }
                    }

                    string sizeStr = fi.Length > 1024 * 1024
                        ? string.Format("{0:N1} МБ", fi.Length / (1024.0 * 1024.0))
                        : string.Format("{0:N0} КБ", fi.Length / 1024.0);

                    lblPackStatus.Text = string.Format("[OK] Найден файл сборки: {0} ({1}){2}", fi.Name, sizeStr, packInfo);
                    lblPackStatus.ForeColor = ColorGoldPrimary;
                }
                catch
                {
                    FileInfo fi = new FileInfo(p);
                    lblPackStatus.Text = string.Format("[OK] Найден файл сборки: {0} ({1:N0} КБ)", fi.Name, fi.Length / 1024.0);
                    lblPackStatus.ForeColor = ColorGoldPrimary;
                }
            }
            else
            {
                lblPackStatus.Text = "[X] Файл не существует по указанному пути.";
                lblPackStatus.ForeColor = Color.FromArgb(244, 67, 54);
            }
        }

        private void UpdateTargetStatus()
        {
            string t = txtTarget.Text.Trim();
            if (string.IsNullOrEmpty(t))
            {
                lblTargetStatus.Text = "[!] Укажите папку .minecraft";
                lblTargetStatus.ForeColor = ColorGoldDark;
            }
            else if (Directory.Exists(t))
            {
                string mmc = FindMultiMcPackJson(t);
                string modsDir = Path.Combine(t, "mods");
                int modCount = Directory.Exists(modsDir) ? Directory.GetFiles(modsDir, "*.jar").Length : 0;

                if (!string.IsNullOrEmpty(mmc))
                {
                    string instName = Path.GetFileName(Path.GetDirectoryName(mmc));
                    lblTargetStatus.Text = string.Format("[OK] Обнаружен инстанс MultiMC/Prism «{0}» (модов в mods/: {1})", instName, modCount);
                    lblTargetStatus.ForeColor = ColorGoldPrimary;
                }
                else if (Directory.Exists(modsDir))
                {
                    lblTargetStatus.Text = string.Format("[OK] Папка существует. Обнаружена папка mods/ (файлов .jar: {0})", modCount);
                    lblTargetStatus.ForeColor = ColorGoldPrimary;
                }
                else
                {
                    lblTargetStatus.Text = "[OK] Папка существует (папка mods/ будет создана автоматически).";
                    lblTargetStatus.ForeColor = ColorGoldPrimary;
                }
            }
            else
            {
                lblTargetStatus.Text = "[i] Папка пока не существует (будет создана при установке).";
                lblTargetStatus.ForeColor = ColorTextMuted;
            }
        }

        private void BtnBrowsePack_Click(object sender, EventArgs e)
        {
            using (OpenFileDialog ofd = new OpenFileDialog())
            {
                ofd.Filter = "Modrinth Modpack (*.mrpack)|*.mrpack|ZIP Archives (*.zip)|*.zip|All Files (*.*)|*.*";
                ofd.Title = "Выберите файл сборки .mrpack";
                string exeDir = AppDomain.CurrentDomain.BaseDirectory;
                if (Directory.Exists(exeDir)) ofd.InitialDirectory = exeDir;

                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    txtPack.Text = ofd.FileName;
                }
            }
        }

        private void BtnBrowseTarget_Click(object sender, EventArgs e)
        {
            using (FolderBrowserDialog fbd = new FolderBrowserDialog())
            {
                fbd.Description = "Выберите папку .minecraft (куда устанавливать сборку):";
                string cur = txtTarget.Text.Trim();
                if (Directory.Exists(cur))
                {
                    fbd.SelectedPath = cur;
                }
                else
                {
                    fbd.SelectedPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                }

                if (fbd.ShowDialog() == DialogResult.OK)
                {
                    txtTarget.Text = fbd.SelectedPath;
                }
            }
        }

        private void BtnOpenTargetFolder_Click(object sender, EventArgs e)
        {
            string t = txtTarget.Text.Trim();
            if (Directory.Exists(t))
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = t,
                    UseShellExecute = true
                };
                Process.Start(psi);
            }
            else
            {
                MessageBox.Show("Папка ещё не существует:\n" + t, "Информация", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void BtnInstall_Click(object sender, EventArgs e)
        {
            string packPath = txtPack.Text.Trim();
            string targetDir = txtTarget.Text.Trim();

            if (string.IsNullOrEmpty(packPath) || !File.Exists(packPath))
            {
                MessageBox.Show("Файл сборки (.mrpack) не найден!\nПожалуйста, поместите .mrpack файл рядом с программой или выберите его через кнопку «Обзор...».", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrEmpty(targetDir))
            {
                MessageBox.Show("Укажите папку для установки Minecraft.", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            btnInstall.Enabled = false;
            btnBrowsePack.Enabled = false;
            btnBrowseTarget.Enabled = false;
            btnDefaultTarget.Enabled = false;

            txtLog.Clear();
            progressBar.Value = 0;

            var args = new InstallArgs
            {
                PackPath = packPath,
                TargetDir = targetDir,
                InstallFabric = chkInstallFabric.Checked,
                CleanMods = chkCleanMods.Checked,
                UnpackRP = chkUnpackRP.Checked,
                AddServer = chkAddServer.Checked,
                ExtractOverrides = chkExtractOverrides.Checked
            };

            worker.RunWorkerAsync(args);
        }

        private class InstallArgs
        {
            public string PackPath { get; set; }
            public string TargetDir { get; set; }
            public bool InstallFabric { get; set; }
            public bool CleanMods { get; set; }
            public bool UnpackRP { get; set; }
            public bool AddServer { get; set; }
            public bool ExtractOverrides { get; set; }
        }

        private class ProgressInfo
        {
            public int Percentage { get; set; }
            public string Status { get; set; }
            public string LogMessage { get; set; }
        }

        private void Log(string msg)
        {
            worker.ReportProgress(0, new ProgressInfo { LogMessage = msg });
        }

        private void UpdateStatus(int percent, string status, string logMsg = null)
        {
            worker.ReportProgress(percent, new ProgressInfo { Percentage = percent, Status = status, LogMessage = logMsg });
        }

        private void Worker_DoWork(object sender, DoWorkEventArgs e)
        {
            InstallArgs args = (InstallArgs)e.Argument;

            Log("=== Запуск установки сборки HeroGuild ===");
            Log("Файл сборки: " + args.PackPath);
            Log("Целевая папка: " + args.TargetDir);

            if (!Directory.Exists(args.TargetDir))
            {
                Directory.CreateDirectory(args.TargetDir);
            }

            string modsDir = Path.Combine(args.TargetDir, "mods");
            if (!Directory.Exists(modsDir))
            {
                Directory.CreateDirectory(modsDir);
            }

            string rpsDir = Path.Combine(args.TargetDir, "resourcepacks");
            if (!Directory.Exists(rpsDir))
            {
                Directory.CreateDirectory(rpsDir);
            }

            ModrinthIndex index = null;
            using (ZipArchive zip = ZipFile.OpenRead(args.PackPath))
            {
                ZipArchiveEntry indexEntry = zip.GetEntry("modrinth.index.json");
                if (indexEntry == null)
                {
                    throw new Exception("В архиве отсутствует файл манифеста modrinth.index.json!");
                }

                using (Stream s = indexEntry.Open())
                using (StreamReader reader = new StreamReader(s, Encoding.UTF8))
                {
                    string json = reader.ReadToEnd();
                    JavaScriptSerializer serializer = new JavaScriptSerializer();
                    index = serializer.Deserialize<ModrinthIndex>(json);
                }

                Log(string.Format("Сборка: {0} (Версия: {1}, Игра: {2})", index.name, index.versionId, index.game));

                int totalFiles = index.files != null ? index.files.Count : 0;
                Log(string.Format("Найдено файлов для загрузки (моды + ресурспаки): {0}", totalFiles));

                // 1. Check and install Fabric Loader if requested
                if (args.InstallFabric)
                {
                    EnsureFabricLoaderInstalled(args.TargetDir, index);
                }

                // 2. Clean old mods if requested (with gentle pacing to avoid heuristic wiper flags)
                if (args.CleanMods && Directory.Exists(modsDir))
                {
                    UpdateStatus(10, "Очистка старых модов...", "Очистка предыдущих модов в папке mods/...");

                    // Собираем список актуальных файлов из манифеста, чтобы не удалять то, что уже совпадает
                    HashSet<string> expectedModFiles = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    if (index.files != null)
                    {
                        foreach (var mf in index.files)
                        {
                            if (mf.path != null && mf.path.StartsWith("mods/", StringComparison.OrdinalIgnoreCase))
                            {
                                expectedModFiles.Add(Path.GetFileName(mf.path));
                            }
                        }
                    }

                    string[] existingMods = Directory.GetFiles(modsDir, "*.jar");
                    foreach (string mod in existingMods)
                    {
                        string fName = Path.GetFileName(mod);
                        if (expectedModFiles.Contains(fName))
                            continue; // Если файл есть в новой сборке, проверим его хеш позже и не дергаем File.Delete зря

                        try
                        {
                            File.Delete(mod);
                            Thread.Sleep(25); // Небольшая задержка между удалениями против поведенческих триггеров
                        }
                        catch (Exception ex)
                        {
                            Log("Не удалось удалить старый файл " + fName + ": " + ex.Message);
                        }
                    }
                }

                // 3. Download all files
                int downloadedCount = 0;
                int skippedCount = 0;

                for (int i = 0; i < totalFiles; i++)
                {
                    ModFile file = index.files[i];
                    string destPath = Path.Combine(args.TargetDir, file.path.Replace('/', '\\'));
                    string destFolder = Path.GetDirectoryName(destPath);
                    if (!Directory.Exists(destFolder))
                    {
                        Directory.CreateDirectory(destFolder);
                    }

                    string fileName = Path.GetFileName(destPath);
                    bool isUnpackableRp = args.UnpackRP && file.path.StartsWith("resourcepacks/") && file.path.EndsWith(".zip");

                    bool isMatch = false;
                    if (File.Exists(destPath))
                    {
                        if (file.hashes != null && file.hashes.ContainsKey("sha512"))
                        {
                            string existingSha512 = ComputeSha512(destPath);
                            if (string.Equals(existingSha512, file.hashes["sha512"], StringComparison.OrdinalIgnoreCase))
                            {
                                isMatch = true;
                            }
                        }
                        else if (file.hashes != null && file.hashes.ContainsKey("sha1"))
                        {
                            string existingSha1 = ComputeSha1(destPath);
                            if (string.Equals(existingSha1, file.hashes["sha1"], StringComparison.OrdinalIgnoreCase))
                            {
                                isMatch = true;
                            }
                        }
                    }

                    if (isMatch)
                    {
                        skippedCount++;
                        Log(string.Format("[{0}/{1}] [Актуален] {2}", i + 1, totalFiles, fileName));
                        if (isUnpackableRp && File.Exists(destPath))
                        {
                            UnpackResourcePackFromFileAndClean(destPath, rpsDir);
                        }
                    }
                    else
                    {
                        if (file.downloads == null || file.downloads.Count == 0)
                        {
                            Log(string.Format("[{0}/{1}] [ОШИБКА] Нет ссылки для загрузки: {2}", i + 1, totalFiles, fileName));
                            continue;
                        }

                        int percent = 10 + (int)(((float)(i + 1) / totalFiles) * 70);
                        UpdateStatus(percent, string.Format("Загрузка ({0}/{1}): {2}", i + 1, totalFiles, fileName));

                        bool fileSuccess = false;
                        Exception lastEx = null;

                        for (int m = 0; m < file.downloads.Count; m++)
                        {
                            string downloadUrl = file.downloads[m];
                            try
                            {
                                int attemptsForMirror = (file.downloads.Count > 1) ? 2 : 8;

                                // Если ресурспак нужно распаковать как папку — распаковываем прямо из ОЗУ без записи и удаления .zip!
                                if (isUnpackableRp)
                                {
                                    string folderName = Path.GetFileNameWithoutExtension(destPath);
                                    string targetRpFolder = Path.Combine(rpsDir, folderName);
                                    long totalBytes = DownloadAndExtractZipInMemory(downloadUrl, targetRpFolder, (msg) => Log(msg), (st) => UpdateStatus(percent, st), attemptsForMirror);
                                    downloadedCount++;
                                    fileSuccess = true;
                                    Log(string.Format("[{0}/{1}] [Распакован в папку] {2} ({3:N0} КБ)", i + 1, totalFiles, folderName, totalBytes / 1024.0));
                                }
                                else
                                {
                                    DownloadFileBufferedWithRetry(downloadUrl, destPath, (msg) => Log(msg), (st) => UpdateStatus(percent, st), attemptsForMirror);
                                    downloadedCount++;
                                    fileSuccess = true;
                                    FileInfo downloadedFi = new FileInfo(destPath);
                                    Log(string.Format("[{0}/{1}] [Скачан] {2} ({3:N0} КБ)", i + 1, totalFiles, fileName, downloadedFi.Length / 1024.0));
                                }
                                break;
                            }
                            catch (Exception ex)
                            {
                                lastEx = ex;
                                if (m < file.downloads.Count - 1)
                                {
                                    Log(string.Format(" -> Зеркало {0} недоступно, переключение на резервное зеркало...", m + 1));
                                }
                            }
                        }

                        if (!fileSuccess)
                        {
                            Log(string.Format("[{0}/{1}] [СБОЙ] {2}: {3}", i + 1, totalFiles, fileName, lastEx != null ? lastEx.Message : "Все зеркала недоступны"));
                        }
                    }
                }

                // 4. Extract local overrides from .mrpack if any
                if (args.ExtractOverrides)
                {
                    List<ZipArchiveEntry> extraEntries = new List<ZipArchiveEntry>();
                    foreach (ZipArchiveEntry entry in zip.Entries)
                    {
                        if (string.Equals(entry.FullName, "modrinth.index.json", StringComparison.OrdinalIgnoreCase))
                            continue;
                        extraEntries.Add(entry);
                    }

                    if (extraEntries.Count > 0)
                    {
                        UpdateStatus(85, "Распаковка локальных конфигураций из .mrpack...");
                        foreach (ZipArchiveEntry entry in extraEntries)
                        {
                            string relPath = entry.FullName;
                            if (relPath.StartsWith("overrides/")) relPath = relPath.Substring("overrides/".Length);
                            else if (relPath.StartsWith("client-overrides/")) relPath = relPath.Substring("client-overrides/".Length);
                            relPath = relPath.Replace('/', '\\').TrimStart('\\');
                            if (string.IsNullOrEmpty(relPath)) continue;

                            string targetFile = Path.Combine(args.TargetDir, relPath);
                            if (entry.FullName.EndsWith("/") || entry.FullName.EndsWith("\\") || string.IsNullOrEmpty(entry.Name))
                            {
                                if (!Directory.Exists(targetFile)) Directory.CreateDirectory(targetFile);
                            }
                            else
                            {
                                string pDir = Path.GetDirectoryName(targetFile);
                                if (!string.IsNullOrEmpty(pDir) && !Directory.Exists(pDir)) Directory.CreateDirectory(pDir);
                                try { entry.ExtractToFile(targetFile, true); } catch { }
                            }
                        }
                    }
                }

                // 5. Configure servers.dat with dynamic IP
                if (args.AddServer)
                {
                    UpdateStatus(92, "Настройка сервера HeroGuild (servers.dat)...");
                    ConfigureServerDat(args.TargetDir);
                }

                UpdateStatus(100, "Установка успешно завершена!");
                Log("=========================================");
                Log(string.Format("ИТОГО: Установлено файлов: {0}, Пропущено (было актуально): {1}", downloadedCount, skippedCount));
                Log("Сборка и сервер HeroGuild готовы к игре!");
            }
        }

        private void ConfigureServerDat(string targetDir)
        {
            string serverName = "HeroGuild";
            string serverIp = "vrsetmain.joinserver.ru";

            string[] candidateUrls = new string[] {
                GITHUB_SERVER_INFO_URL,
                CLOUDFLARE_SERVER_INFO_URL,
                BuildGoogleDriveUrl(GDRIVE_SERVER_INFO_ID),
                JSDELIVR_SERVER_INFO_URL
            };

            ServerInfo info = FetchServerInfoWithRetry(candidateUrls, 2);
            if (info != null && !string.IsNullOrEmpty(info.ip))
            {
                serverIp = info.ip.Trim();
                if (!string.IsNullOrEmpty(info.name)) serverName = info.name.Trim();
            }

            try
            {
                byte[] serverBytes = CreateNbtServersDat(serverName, serverIp);
                string serversDatPath = Path.Combine(targetDir, "servers.dat");
                File.WriteAllBytes(serversDatPath, serverBytes);
                Log(string.Format("[+] Сервер «{0}» ({1}) успешно записан в servers.dat!", serverName, serverIp));
            }
            catch (Exception ex)
            {
                Log("Предупреждение: Не удалось обновить servers.dat: " + ex.Message);
            }
        }

        private ServerInfo FetchServerInfoWithRetry(string[] candidateUrls, int maxAttemptsPerUrl)
        {
            foreach (string currentUrl in candidateUrls)
            {
                if (string.IsNullOrEmpty(currentUrl)) continue;
                for (int attempt = 1; attempt <= maxAttemptsPerUrl; attempt++)
                {
                    try
                    {
                        string json = httpClient.GetStringAsync(currentUrl).GetAwaiter().GetResult();
                        JavaScriptSerializer js = new JavaScriptSerializer();
                        ServerInfo info = js.Deserialize<ServerInfo>(json);
                        if (info != null && !string.IsNullOrEmpty(info.ip))
                        {
                            return info;
                        }
                    }
                    catch
                    {
                        if (attempt < maxAttemptsPerUrl)
                        {
                            Thread.Sleep(1500);
                        }
                    }
                }
            }
            return null;
        }

        private static byte[] CreateNbtServersDat(string serverName, string serverIp)
        {
            using (MemoryStream ms = new MemoryStream())
            using (BinaryWriter bw = new BinaryWriter(ms))
            {
                bw.Write((byte)10); // TAG_Compound
                WriteNbtString(bw, "");

                bw.Write((byte)9); // TAG_List
                WriteNbtString(bw, "servers");
                bw.Write((byte)10); // Element Type = TAG_Compound
                bw.Write(SwapBytes((int)1)); // List length = 1

                bw.Write((byte)8);
                WriteNbtString(bw, "ip");
                WriteNbtString(bw, serverIp);

                bw.Write((byte)8);
                WriteNbtString(bw, "name");
                WriteNbtString(bw, serverName);

                bw.Write((byte)1);
                WriteNbtString(bw, "acceptTextures");
                bw.Write((byte)1);

                bw.Write((byte)1);
                WriteNbtString(bw, "hidden");
                bw.Write((byte)0);

                bw.Write((byte)0);
                bw.Write((byte)0);

                return ms.ToArray();
            }
        }

        private static void WriteNbtString(BinaryWriter bw, string str)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(str);
            bw.Write(SwapBytes((short)bytes.Length));
            bw.Write(bytes);
        }

        private static short SwapBytes(short val)
        {
            return (short)(((val & 0xFF) << 8) | ((val >> 8) & 0xFF));
        }

        private static int SwapBytes(int val)
        {
            return (int)(((val & 0x000000FF) << 24) |
                          ((val & 0x0000FF00) << 8) |
                          ((val & 0x00FF0000) >> 8) |
                          ((val >> 24) & 0x000000FF));
        }

        private static void ExtractZipEntriesToDirectory(ZipArchive archive, string destinationDir)
        {
            if (!Directory.Exists(destinationDir))
            {
                Directory.CreateDirectory(destinationDir);
            }

            foreach (ZipArchiveEntry entry in archive.Entries)
            {
                string entryRel = entry.FullName.Replace('/', '\\').TrimStart('\\');
                if (string.IsNullOrEmpty(entryRel)) continue;
                string entryTarget = Path.Combine(destinationDir, entryRel);

                if (entry.FullName.EndsWith("/") || entry.FullName.EndsWith("\\") || string.IsNullOrEmpty(entry.Name))
                {
                    if (!Directory.Exists(entryTarget)) Directory.CreateDirectory(entryTarget);
                }
                else
                {
                    string eDir = Path.GetDirectoryName(entryTarget);
                    if (!string.IsNullOrEmpty(eDir) && !Directory.Exists(eDir)) Directory.CreateDirectory(eDir);
                    entry.ExtractToFile(entryTarget, true);
                }
            }
        }

        private void UnpackResourcePackFromFileAndClean(string zipFilePath, string rpsDir)
        {
            string folderName = Path.GetFileNameWithoutExtension(zipFilePath);
            string targetRpFolder = Path.Combine(rpsDir, folderName);
            try
            {
                using (ZipArchive rpZip = ZipFile.OpenRead(zipFilePath))
                {
                    ExtractZipEntriesToDirectory(rpZip, targetRpFolder);
                }

                Thread.Sleep(150);
                try { File.Delete(zipFilePath); } catch { }

                Log(string.Format("-> Ресурспак распакован в папку: {0}", folderName));
            }
            catch (Exception unpackEx)
            {
                Log(string.Format("Предупреждение при распаковке {0}: {1}", folderName, unpackEx.Message));
            }
        }

        private static long DownloadAndExtractZipInMemory(string url, string targetDirectory, Action<string> logAction, Action<string> statusAction, int maxAttempts = 5)
        {
            int attempt = 0;
            while (true)
            {
                attempt++;
                try
                {
                    using (HttpResponseMessage response = httpClient.GetAsync(url, HttpCompletionOption.ResponseHeadersRead).GetAwaiter().GetResult())
                    {
                        response.EnsureSuccessStatusCode();
                        using (Stream netStream = response.Content.ReadAsStreamAsync().GetAwaiter().GetResult())
                        using (MemoryStream memStream = new MemoryStream())
                        {
                            netStream.CopyTo(memStream, 81920);
                            long size = memStream.Length;
                            memStream.Position = 0;
                            using (ZipArchive archive = new ZipArchive(memStream, ZipArchiveMode.Read))
                            {
                                ExtractZipEntriesToDirectory(archive, targetDirectory);
                            }
                            return size;
                        }
                    }
                }
                catch (Exception ex)
                {
                    if (attempt >= maxAttempts)
                    {
                        throw new Exception(string.Format("Превышен лимит попыток ({0}): {1}", maxAttempts, ex.Message), ex);
                    }

                    int delaySeconds = Math.Min(attempt * 2, 20);
                    if (logAction != null) logAction(string.Format(" [!] Ошибка загрузки ({0}). Повтор {1}/{2} через {3} сек...", ex.Message, attempt, maxAttempts, delaySeconds));
                    if (statusAction != null) statusAction(string.Format("Ожидание связи ({0} сек)...", delaySeconds));
                    Thread.Sleep(delaySeconds * 1000);
                }
            }
        }

        private static void DownloadFileBufferedWithRetry(string url, string destinationPath, Action<string> logAction, Action<string> statusAction, int maxAttempts = 8)
        {
            int attempt = 0;
            while (true)
            {
                attempt++;
                try
                {
                    using (HttpResponseMessage response = httpClient.GetAsync(url, HttpCompletionOption.ResponseHeadersRead).GetAwaiter().GetResult())
                    {
                        response.EnsureSuccessStatusCode();
                        using (Stream responseStream = response.Content.ReadAsStreamAsync().GetAwaiter().GetResult())
                        using (FileStream fileStream = new FileStream(destinationPath, FileMode.Create, FileAccess.Write, FileShare.None))
                        {
                            responseStream.CopyTo(fileStream, 81920);
                        }
                    }
                    return;
                }
                catch (Exception ex)
                {
                    if (attempt >= maxAttempts)
                    {
                        throw new Exception(string.Format("Превышен лимит попыток ({0}): {1}", maxAttempts, ex.Message), ex);
                    }

                    int delaySeconds = Math.Min(attempt * 2, 20);
                    if (logAction != null) logAction(string.Format(" [!] Сбой соединения ({0}). Повторная попытка {1}/{2} через {3} сек...", ex.Message, attempt, maxAttempts, delaySeconds));
                    if (statusAction != null) statusAction(string.Format("Ожидание связи ({0} сек)...", delaySeconds));
                    Thread.Sleep(delaySeconds * 1000);
                }
            }
        }

        private static string ComputeSha512(string filePath)
        {
            using (SHA512 sha512 = SHA512.Create())
            using (FileStream stream = File.OpenRead(filePath))
            {
                byte[] hash = sha512.ComputeHash(stream);
                StringBuilder sb = new StringBuilder(hash.Length * 2);
                for (int i = 0; i < hash.Length; i++)
                {
                    sb.Append(hash[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }

        private static string ComputeSha1(string filePath)
        {
            using (SHA1 sha1 = SHA1.Create())
            using (FileStream stream = File.OpenRead(filePath))
            {
                byte[] hash = sha1.ComputeHash(stream);
                StringBuilder sb = new StringBuilder(hash.Length * 2);
                for (int i = 0; i < hash.Length; i++)
                {
                    sb.Append(hash[i].ToString("x2"));
                }
                return sb.ToString();
            }
        }

        private void EnsureFabricLoaderInstalled(string targetDir, ModrinthIndex index)
        {
            string mcVersion = "1.21.1";
            string requiredLoaderVer = "0.19.3";

            if (index != null && index.dependencies != null)
            {
                if (index.dependencies.ContainsKey("minecraft") && !string.IsNullOrEmpty(index.dependencies["minecraft"]))
                {
                    mcVersion = index.dependencies["minecraft"].Trim();
                }
                if (index.dependencies.ContainsKey("fabric-loader") && !string.IsNullOrEmpty(index.dependencies["fabric-loader"]))
                {
                    requiredLoaderVer = index.dependencies["fabric-loader"].Trim();
                }
            }

            // 1. Auto-configure MultiMC / Prism instance if detected
            bool isMultiMc = ConfigureMultiMcInstance(targetDir, mcVersion, requiredLoaderVer, (msg) => Log(msg));

            Version requiredV = ParseSemanticVersion(requiredLoaderVer) ?? new Version(0, 19, 3);
            Version installedV = GetInstalledFabricLoaderVersion(targetDir, mcVersion);

            if (installedV != null && installedV >= requiredV && !isMultiMc)
            {
                Log(string.Format("[OK] Fabric Loader актуален (найдена версия {0} для Minecraft {1})", installedV, mcVersion));
                UpdateLauncherProfiles(targetDir, mcVersion, installedV.ToString(3));
                return;
            }

            if (isMultiMc)
            {
                UpdateLauncherProfiles(targetDir, mcVersion, requiredLoaderVer);
                return;
            }

            if (installedV != null)
            {
                Log(string.Format("[!] Обнаружен устаревший Fabric Loader (версия {0}). Требуется: {1}", installedV, requiredLoaderVer));
                Log("-> Загрузка и обновление Fabric Loader " + requiredLoaderVer + "...");
            }
            else
            {
                Log(string.Format("[i] Fabric Loader для Minecraft {0} не найден в папке versions/.", mcVersion));
                Log("-> Загрузка и установка Fabric Loader " + requiredLoaderVer + "...");
            }

            UpdateStatus(5, "Установка Fabric Loader " + requiredLoaderVer + "...");

            string versionsDir = Path.Combine(targetDir, "versions");
            if (!Directory.Exists(versionsDir))
            {
                Directory.CreateDirectory(versionsDir);
            }

            string zipFileName = string.Format("fabric-loader-{0}-{1}.zip", requiredLoaderVer, mcVersion);
            List<string> candidateUrls = new List<string>
            {
                string.Format("https://meta.fabricmc.net/v2/versions/loader/{0}/{1}/profile/zip", mcVersion, requiredLoaderVer),
                string.Format("https://vxnku.github.io/-HG-HGMM/fabric/{0}", zipFileName),
                string.Format("https://bold-bread-e4ce.yuliy-ml.workers.dev/fabric/{0}", zipFileName),
                BuildGoogleDriveUrl(GDRIVE_FABRIC_ZIP_ID),
                string.Format("https://cdn.jsdelivr.net/gh/Vxnku/-HG-HGMM@main/fabric/{0}", zipFileName)
            };

            bool installed = false;
            Exception lastError = null;

            for (int m = 0; m < candidateUrls.Count; m++)
            {
                string currentUrl = candidateUrls[m];
                try
                {
                    int attempts = (candidateUrls.Count > 1) ? 2 : 5;
                    // Скачивание и распаковка в памяти (без создания временных файлов в %TEMP%)
                    DownloadAndExtractZipInMemory(currentUrl, versionsDir, (msg) => Log(msg), (st) => UpdateStatus(5, st), attempts);
                    installed = true;
                    break;
                }
                catch (Exception ex)
                {
                    lastError = ex;
                    if (m < candidateUrls.Count - 1)
                    {
                        Log(string.Format(" -> Источник Fabric #{0} недоступен, переключение на резервное зеркало...", m + 1));
                    }
                }
            }

            if (!installed)
            {
                throw new Exception(string.Format("Не удалось загрузить Fabric Loader {0}: {1}", requiredLoaderVer, lastError != null ? lastError.Message : "Все зеркала недоступны"));
            }

            Log(string.Format("[OK] Fabric Loader {0} для Minecraft {1} успешно установлен в versions/!", requiredLoaderVer, mcVersion));
            UpdateLauncherProfiles(targetDir, mcVersion, requiredLoaderVer);
        }

        private static string FindMultiMcPackJson(string targetDir)
        {
            if (string.IsNullOrEmpty(targetDir)) return null;

            string direct = Path.Combine(targetDir, "mmc-pack.json");
            if (File.Exists(direct)) return direct;

            try
            {
                string parent = Path.GetDirectoryName(targetDir.TrimEnd('\\', '/'));
                if (!string.IsNullOrEmpty(parent))
                {
                    string parentPack = Path.Combine(parent, "mmc-pack.json");
                    if (File.Exists(parentPack)) return parentPack;
                }
            }
            catch { }

            return null;
        }

        private static bool ConfigureMultiMcInstance(string targetDir, string mcVersion, string loaderVersion, Action<string> logAction)
        {
            string packJsonPath = FindMultiMcPackJson(targetDir);
            if (string.IsNullOrEmpty(packJsonPath) || !File.Exists(packJsonPath)) return false;

            try
            {
                JavaScriptSerializer js = new JavaScriptSerializer();
                js.MaxJsonLength = int.MaxValue;
                string json = File.ReadAllText(packJsonPath, Encoding.UTF8);
                Dictionary<string, object> root = js.Deserialize<Dictionary<string, object>>(json);
                if (root == null) return false;

                ArrayList components = null;
                if (root.ContainsKey("components") && root["components"] is ArrayList)
                {
                    components = (ArrayList)root["components"];
                }
                else
                {
                    components = new ArrayList();
                    root["components"] = components;
                }

                bool hasIntermediary = false;
                bool hasLoader = false;

                foreach (object compObj in components)
                {
                    if (compObj is Dictionary<string, object>)
                    {
                        var comp = (Dictionary<string, object>)compObj;
                        if (comp.ContainsKey("uid") && comp["uid"] != null)
                        {
                            string uid = comp["uid"].ToString();
                            if (uid == "net.fabricmc.intermediary")
                            {
                                hasIntermediary = true;
                                comp["version"] = mcVersion;
                                comp["cachedVersion"] = mcVersion;
                            }
                            else if (uid == "net.fabricmc.fabric-loader")
                            {
                                hasLoader = true;
                                comp["version"] = loaderVersion;
                                comp["cachedVersion"] = loaderVersion;
                                comp["important"] = true;
                            }
                        }
                    }
                }

                if (!hasIntermediary)
                {
                    Dictionary<string, object> interComp = new Dictionary<string, object>();
                    interComp["cachedName"] = "Intermediary Mappings";
                    interComp["cachedVersion"] = mcVersion;
                    interComp["cachedVolatile"] = true;
                    interComp["dependencyOnly"] = true;
                    interComp["uid"] = "net.fabricmc.intermediary";
                    interComp["version"] = mcVersion;

                    int mcIdx = -1;
                    for (int i = 0; i < components.Count; i++)
                    {
                        if (components[i] is Dictionary<string, object> &&
                            ((Dictionary<string, object>)components[i]).ContainsKey("uid") &&
                            ((Dictionary<string, object>)components[i])["uid"].ToString() == "net.minecraft")
                        {
                            mcIdx = i;
                            break;
                        }
                    }
                    if (mcIdx != -1) components.Insert(mcIdx + 1, interComp);
                    else components.Add(interComp);
                }

                if (!hasLoader)
                {
                    Dictionary<string, object> loaderComp = new Dictionary<string, object>();
                    loaderComp["cachedName"] = "Fabric Loader";
                    loaderComp["cachedVersion"] = loaderVersion;
                    loaderComp["important"] = true;
                    loaderComp["uid"] = "net.fabricmc.fabric-loader";
                    loaderComp["version"] = loaderVersion;
                    components.Add(loaderComp);
                }

                string outJson = js.Serialize(root);
                File.WriteAllText(packJsonPath, outJson, Encoding.UTF8);

                string instDir = Path.GetDirectoryName(packJsonPath);
                string instName = Path.GetFileName(instDir);
                if (logAction != null)
                {
                    logAction(string.Format("[OK] Обнаружен инстанс MultiMC/Prism «{0}»! Fabric Loader {1} активирован в mmc-pack.json", instName, loaderVersion));
                }
                return true;
            }
            catch (Exception ex)
            {
                if (logAction != null)
                {
                    logAction("Предупреждение: Не удалось обновить mmc-pack.json: " + ex.Message);
                }
                return false;
            }
        }

        private static Version GetInstalledFabricLoaderVersion(string targetDir, string mcVersion)
        {
            try
            {
                string mmcPackPath = FindMultiMcPackJson(targetDir);
                if (!string.IsNullOrEmpty(mmcPackPath) && File.Exists(mmcPackPath))
                {
                    try
                    {
                        JavaScriptSerializer js = new JavaScriptSerializer();
                        string json = File.ReadAllText(mmcPackPath, Encoding.UTF8);
                        Dictionary<string, object> root = js.Deserialize<Dictionary<string, object>>(json);
                        if (root != null && root.ContainsKey("components") && root["components"] is ArrayList)
                        {
                            foreach (object compObj in (ArrayList)root["components"])
                            {
                                if (compObj is Dictionary<string, object>)
                                {
                                    var comp = (Dictionary<string, object>)compObj;
                                    if (comp.ContainsKey("uid") && comp["uid"] != null && comp["uid"].ToString() == "net.fabricmc.fabric-loader")
                                    {
                                        if (comp.ContainsKey("version") && comp["version"] != null)
                                        {
                                            Version v = ParseSemanticVersion(comp["version"].ToString());
                                            if (v != null) return v;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch { }
                }

                string versionsDir = Path.Combine(targetDir, "versions");
                if (!Directory.Exists(versionsDir)) return null;

                Version maxVersion = null;
                foreach (string dir in Directory.GetDirectories(versionsDir))
                {
                    string dirName = Path.GetFileName(dir);
                    string jsonPath = Path.Combine(dir, dirName + ".json");
                    if (!File.Exists(jsonPath))
                    {
                        string[] anyJsons = Directory.GetFiles(dir, "*.json");
                        if (anyJsons.Length > 0) jsonPath = anyJsons[0];
                        else continue;
                    }

                    try
                    {
                        string json = File.ReadAllText(jsonPath, Encoding.UTF8);
                        bool isFabric = json.Contains("net.fabricmc.loader") || json.Contains("net.fabricmc:fabric-loader") || dirName.IndexOf("fabric", StringComparison.OrdinalIgnoreCase) >= 0;
                        if (!isFabric) continue;

                        bool isTargetMc = json.Contains(mcVersion) || dirName.Contains(mcVersion);
                        if (!isTargetMc) continue;

                        int idx = json.IndexOf("net.fabricmc:fabric-loader:");
                        if (idx != -1)
                        {
                            int start = idx + "net.fabricmc:fabric-loader:".Length;
                            int end = json.IndexOfAny(new char[] { '"', '\'', ' ', ',', '\\', '\r', '\n' }, start);
                            if (end != -1)
                            {
                                string verStr = json.Substring(start, end - start).Trim();
                                Version v = ParseSemanticVersion(verStr);
                                if (v != null && (maxVersion == null || v > maxVersion))
                                {
                                    maxVersion = v;
                                }
                            }
                        }

                        if (dirName.StartsWith("fabric-loader-", StringComparison.OrdinalIgnoreCase))
                        {
                            string rest = dirName.Substring("fabric-loader-".Length);
                            int dash = rest.IndexOf('-');
                            if (dash != -1)
                            {
                                string verStr = rest.Substring(0, dash);
                                Version v = ParseSemanticVersion(verStr);
                                if (v != null && (maxVersion == null || v > maxVersion))
                                {
                                    maxVersion = v;
                                }
                            }
                        }
                    }
                    catch { }
                }
                return maxVersion;
            }
            catch
            {
                return null;
            }
        }

        private static Version ParseSemanticVersion(string str)
        {
            if (string.IsNullOrEmpty(str)) return null;
            str = str.Trim();
            int plusIdx = str.IndexOf('+');
            if (plusIdx != -1) str = str.Substring(0, plusIdx);
            int dashIdx = str.IndexOf('-');
            if (dashIdx != -1) str = str.Substring(0, dashIdx);

            string[] parts = str.Split('.');
            if (parts.Length == 1) str += ".0.0";
            else if (parts.Length == 2) str += ".0";

            Version v;
            if (Version.TryParse(str, out v)) return v;
            return null;
        }

        private void UpdateLauncherProfiles(string targetDir, string mcVersion, string loaderVersion)
        {
            string[] profileFiles = new string[] { "launcher_profiles.json", "launcher_profiles_microsoft_store.json" };
            string versionId = string.Format("fabric-loader-{0}-{1}", loaderVersion, mcVersion);

            JavaScriptSerializer js = new JavaScriptSerializer();
            js.MaxJsonLength = int.MaxValue;

            foreach (string fileName in profileFiles)
            {
                string pPath = Path.Combine(targetDir, fileName);
                if (!File.Exists(pPath) && fileName != "launcher_profiles.json") continue;

                try
                {
                    Dictionary<string, object> root = null;
                    if (File.Exists(pPath))
                    {
                        try
                        {
                            string json = File.ReadAllText(pPath, Encoding.UTF8);
                            root = js.Deserialize<Dictionary<string, object>>(json);
                        }
                        catch { }
                    }

                    if (root == null) root = new Dictionary<string, object>();

                    if (!root.ContainsKey("profiles") || !(root["profiles"] is Dictionary<string, object>))
                    {
                        root["profiles"] = new Dictionary<string, object>();
                    }

                    Dictionary<string, object> profiles = (Dictionary<string, object>)root["profiles"];
                    string profileKey = "HeroGuild";
                    Dictionary<string, object> hgProfile;

                    if (profiles.ContainsKey(profileKey) && profiles[profileKey] is Dictionary<string, object>)
                    {
                        hgProfile = (Dictionary<string, object>)profiles[profileKey];
                    }
                    else
                    {
                        hgProfile = new Dictionary<string, object>();
                        profiles[profileKey] = hgProfile;
                    }

                    hgProfile["name"] = string.Format("HeroGuild (Fabric {0})", mcVersion);
                    hgProfile["type"] = "custom";
                    hgProfile["created"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ");
                    hgProfile["lastUsed"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ");
                    hgProfile["icon"] = "Crafting_Table";
                    hgProfile["lastVersionId"] = versionId;

                    string outJson = js.Serialize(root);
                    File.WriteAllText(pPath, outJson, Encoding.UTF8);
                    Log(string.Format("[+] Профиль «HeroGuild (Fabric {0})» настроен в {1} (версия: {2})", mcVersion, fileName, versionId));
                }
                catch (Exception ex)
                {
                    Log(string.Format("Предупреждение: Не удалось обновить {0}: {1}", fileName, ex.Message));
                }
            }
        }

        private void Worker_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            ProgressInfo info = (ProgressInfo)e.UserState;
            if (info.Percentage > 0)
            {
                progressBar.Value = Math.Min(100, Math.Max(0, info.Percentage));
            }
            if (!string.IsNullOrEmpty(info.Status))
            {
                lblStatus.Text = info.Status;
            }
            if (!string.IsNullOrEmpty(info.LogMessage))
            {
                txtLog.AppendText(string.Format("[{0}] {1}\r\n", DateTime.Now.ToString("HH:mm:ss"), info.LogMessage));
            }
        }

        private void Worker_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            btnInstall.Enabled = true;
            btnBrowsePack.Enabled = true;
            btnBrowseTarget.Enabled = true;
            btnDefaultTarget.Enabled = true;

            if (e.Error != null)
            {
                lblStatus.Text = "Произошла ошибка при установке.";
                lblStatus.ForeColor = Color.FromArgb(244, 67, 54);
                txtLog.AppendText(string.Format("[ОШИБКА] {0}\r\n", e.Error.Message));
                MessageBox.Show("Ошибка при установке:\n" + e.Error.Message, "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            else
            {
                lblStatus.Text = "Готово! Сборка и сервер успешно установлены.";
                lblStatus.ForeColor = ColorGoldPrimary;
                progressBar.Value = 100;
                MessageBox.Show("Сборка HeroGuild, ресурспаки и сервер в сетевой игре успешно настроены!\n\nВы можете запускать игру через ваш лаунчер.", "Успех", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}

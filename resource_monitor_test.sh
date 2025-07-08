#!/usr/bin/env bash

# ===================== Configuration =====================
servers=(
  EMIMDGXA100GPU{1..8}.partners.org
  mgbaimlph100-01.partners.org
  mgbaimlph100-02.partners.org
)

cluster_ip="10.162.9.176"
# mailto=("abc@example.com")
report_file="/tmp/server_report_$(date +%F).txt"

# Clear report file
echo "Resource Monitoring Report - $(date)" | tee "$report_file"
echo "====================================" | tee -a "$report_file"
echo "" | tee -a "$report_file"

# ===================== Regular Server Monitoring =====================
for host in "${servers[@]}"; do
  echo "Checking server: $host" | tee -a "$report_file"

  if ! ssh -o ConnectTimeout=5 "$host" "echo ok" &>/dev/null; then
    echo "  ⚠ Unable to access $host, skipping" | tee -a "$report_file"
    echo "" | tee -a "$report_file"
    continue
  fi

  # Determine which disk path to check
  if [[ "$host" == "mgbaimlph100-01.partners.org" || "$host" == "mgbaimlph100-02.partners.org" ]]; then
    disk_path="/dev/md0"
  else
    disk_path="/dev/mapper/ubuntu--vg-ubuntu--lv"
  fi

  ssh "$host" bash <<EOF | tee -a "$report_file"
echo "  GPU Usage:"
if command -v nvidia-smi &>/dev/null; then
  nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits | \
  while IFS=',' read -r pid mem; do
    if [[ -n "\$pid" ]]; then
      user=\$(ps -o user= -p "\$pid" 2>/dev/null)
      echo "    \$user | GPU Memory Usage: \${mem} MiB (pid=\$pid)"
    fi
  done
else
  echo "    nvidia-smi not installed or not available"
fi

echo ""
echo "  Disk Usage ($disk_path):"
df -h | grep '$disk_path' | \
awk '{printf "    Size: %s  Used: %s  Avail: %s  Use%%: %s\n", \$2, \$3, \$4, \$5}'
EOF

  echo "" | tee -a "$report_file"
done

# ===================== Slurm Cluster Monitoring =====================
echo "Checking Slurm cluster ($cluster_ip)" | tee -a "$report_file"
if ssh -o ConnectTimeout=5 zl8@"$cluster_ip" "echo ok" &>/dev/null; then
  echo "  Slurm Queue:" | tee -a "$report_file"
  echo "    USER              NODES  NODELIST(REASON)" | tee -a "$report_file"
  ssh zl8@"$cluster_ip" 'source /etc/profile; module load slurm; squeue -o "%.18u %.5D %.40R" | tail -n +2' | tee -a "$report_file"
else
  echo "  ⚠ Unable to access cluster $cluster_ip" | tee -a "$report_file"
fi
echo "" | tee -a "$report_file"

# ===================== Email Sending =====================
subject="Daily Resource Monitoring Report: $(date +%F)"
mail_cmd=$(command -v mailx || command -v mail)

if [[ -n "$mail_cmd" ]]; then
  for addr in "${mailto[@]}"; do
    cat "$report_file" | $mail_cmd -s "$subject" "$addr"
  done
else
  echo "⚠ 'mail' or 'mailx' command not found. Cannot send email." | tee -a "$report_file"
fi


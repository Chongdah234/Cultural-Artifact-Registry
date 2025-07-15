# 🏛️ Cultural Artifact Registry

A Stacks blockchain smart contract for preserving cultural heritage through community-driven artifact documentation, storytelling, and donations.

## 🌟 Features

- **🎨 Artifact Minting**: Create digital records of cultural artifacts with rich metadata
- **📚 Story Recording**: Add personal narratives and historical accounts to artifacts  
- **💰 Community Donations**: Support artifact preservation through STX donations
- **✅ Verification System**: Official verification of artifacts and stories
- **👥 User Profiles**: Build reputation through contributions
- **🏘️ Community Roles**: Assign roles within cultural communities

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testnet/mainnet deployment

### Installation
```bash
git clone <repository-url>
cd Cultural-Artifact-Registry
clarinet integrate
```

### Testing
```bash
clarinet test
```

## 📖 Usage

### Minting an Artifact 🎭

```clarity
(contract-call? .cultural-artifact-registry mint-artifact
  "Ancient Pottery Vase"
  "A ceremonial vase from the Ming Dynasty found in local excavations"
  "Beijing, China"
  "Ming Dynasty (1368-1644)"
  "Used in royal ceremonies and represents the pinnacle of ceramic artistry"
  "https://example.com/vase-image.jpg")
```

### Adding a Story 📝

```clarity
(contract-call? .cultural-artifact-registry add-story
  u1  ;; artifact-id
  "My Grandmother's Tale"
  "My grandmother told me this vase was used in her village's harvest festival..."
  (some "https://example.com/audio-story.mp3"))
```

### Making a Donation 💝

```clarity
(contract-call? .cultural-artifact-registry donate-to-artifact
  u1      ;; artifact-id
  u1000)  ;; amount in microSTX
```

### Updating Your Profile 👤

```clarity
(contract-call? .cultural-artifact-registry update-profile
  "Cultural Historian"
  "Passionate about preserving our shared heritage through digital archives")
```

## 🔍 Read-Only Functions

### Get Artifact Information
```clarity
(contract-call? .cultural-artifact-registry get-artifact u1)
```

### Get Story Details
```clarity
(contract-call? .cultural-artifact-registry get-story u1 u1)
```

### Check User Profile
```clarity
(contract-call? .cultural-artifact-registry get-user-profile 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🏗️ Contract Structure

### Data Maps
- **artifacts**: Core artifact metadata and information
- **artifact-stories**: Community stories and narratives
- **user-profiles**: User reputation and statistics
- **artifact-donations**: Donation tracking
- **community-roles**: Community management

### Key Functions
- `mint-artifact`: Create new cultural artifacts
- `add-story`: Record stories about artifacts
- `donate-to-artifact`: Support preservation efforts
- `verify-artifact`/`verify-story`: Admin verification
- `update-profile`: Manage user profiles

## 🎯 Use Cases

### 🏛️ Museums & Cultural Institutions
- Digitize collections with community stories
- Enable public engagement through donations
- Verify authenticity of submissions

### 🌍 Indigenous Communities  
- Preserve traditional knowledge and oral histories
- Control narrative around cultural artifacts
- Generate funding for preservation projects

### 🎓 Educational Organizations
- Create interactive learning experiences
- Crowdsource historical documentation
- Build collaborative heritage projects

### 👥 Local Communities
- Document neighborhood history
- Preserve family heirlooms digitally
- Share cultural memories across generations

## 🔐 Security Features

- **Access Control**: Owner-only verification functions
- **Input Validation**: Metadata length and content checks
- **Financial Safety**: Secure STX transfer mechanisms
- **Data Integrity**: Immutable artifact and story records

## 📊 Reputation System

Users earn reputation points by:
- Minting artifacts: **+10 points** 🎨
- Adding stories: **+5 points** 📖
- Community verification: **Bonus points** ⭐

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📜 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

Built with ❤️ for preserving cultural heritage on the Stacks blockchain.

---

*Preserving the past, building the future* 🌟

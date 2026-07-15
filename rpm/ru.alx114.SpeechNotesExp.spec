Name:       ru.alx114.SpeechNotesExp
Summary:    SpeechNotes voice recorder
Version:    0.1
Release:    1
License:    BSD-3-Clause
Source0:    %{name}-%{version}.tar.bz2

Requires:      sailfishsilica-qt5 >= 0.10.9
BuildRequires: pkgconfig(auroraapp)
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(Qt5Multimedia)

%description
SpeechNotes - voice recorder with offline transcription.

%prep
%autosetup

%build
%qmake5
%make_build

%install
%make_install

mkdir -p %{buildroot}%{_datadir}/%{name}/models
install -m 644 models/ggml-tiny-q8_0.bin %{buildroot}%{_datadir}/%{name}/models/
install -m 644 models/ggml-small-q8_0.bin %{buildroot}%{_datadir}/%{name}/models/

mkdir -p %{buildroot}%{_datadir}/icons/hicolor/86x86/apps
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/108x108/apps
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/128x128/apps
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/172x172/apps
install -m 644 icons/86x86/%{name}.png %{buildroot}%{_datadir}/icons/hicolor/86x86/apps/%{name}.png
install -m 644 icons/108x108/%{name}.png %{buildroot}%{_datadir}/icons/hicolor/108x108/apps/%{name}.png
install -m 644 icons/128x128/%{name}.png %{buildroot}%{_datadir}/icons/hicolor/128x128/apps/%{name}.png
install -m 644 icons/172x172/%{name}.png %{buildroot}%{_datadir}/icons/hicolor/172x172/apps/%{name}.png

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%defattr(644,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
